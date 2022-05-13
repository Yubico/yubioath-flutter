package com.yubico.authenticator.oath

import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.Observer
import com.yubico.authenticator.*
import com.yubico.authenticator.api.Pigeon.*
import com.yubico.authenticator.logging.Log
import com.yubico.authenticator.management.model
import com.yubico.authenticator.management.Model.AppDeviceInfo
import com.yubico.authenticator.oath.keystore.ClearingMemProvider
import com.yubico.authenticator.oath.keystore.KeyStoreProvider
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.Logger
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.fido.FidoConnection
import com.yubico.yubikit.core.otp.OtpConnection
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.oath.*
import com.yubico.yubikit.support.DeviceUtil
import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.*
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.IOException
import java.net.URI
import java.util.concurrent.Executors
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

class OathManager(
    private val lifecycleOwner: LifecycleOwner,
    messenger: BinaryMessenger,
    appContext: AppContext,
    private val appViewModel: MainViewModel,
    private val dialogManager: DialogManager
) : OathApi {

    private val _dispatcher = Executors.newSingleThreadExecutor().asCoroutineDispatcher()
    private val coroutineScope = CoroutineScope(SupervisorJob() + _dispatcher)

    private val _fOathApi: FOathApi = FOathApi(messenger)
    private val _fManagementApi: FManagementApi = FManagementApi(messenger)

    private val _memoryKeyProvider = ClearingMemProvider()
    private val _keyManager = KeyManager(KeyStoreProvider(), _memoryKeyProvider)
    private var _previousNfcDeviceId = ""

    private val _pendingYubiKeyAction = MutableLiveData<YubiKeyAction?>()
    private val pendingYubiKeyAction: LiveData<YubiKeyAction?> = _pendingYubiKeyAction

    private val _model = Model()

    init {
        OathApi.setup(messenger, this)

        appContext.appContext.observe(lifecycleOwner) {
            if (it == OperationContext.Oath) {
                installObservers()
            } else {
                uninstallObservers()
            }
        }
    }

    companion object {
        const val TAG = "OathManager"
    }

    private val deviceObserver =
        Observer<YubiKeyDevice?> { yubiKeyDevice ->
            if (yubiKeyDevice != null) {
                yubikeyAttached(yubiKeyDevice)
            } else {
                yubikeyDetached()
            }
        }

    private fun installObservers() {
        Log.d(TAG, "Installed oath observers")
        appViewModel.yubiKeyDevice.observe(lifecycleOwner, deviceObserver)
    }

    private fun uninstallObservers() {
        appViewModel.yubiKeyDevice.removeObserver(deviceObserver)
        Log.d(TAG, "Uninstalled oath observers")
    }

    private suspend fun provideYubiKey(result: com.yubico.yubikit.core.util.Result<YubiKeyDevice, Exception>) =
        pendingYubiKeyAction.value?.let {
            _pendingYubiKeyAction.postValue(null)
            it.action.invoke(result)
        } ?: run {
            Log.e(TAG, "The pending action is not valid anymore")
            throw IllegalStateException("The pending action is not valid anymore")
        }

    private var _isUsbKey = false
    private fun yubikeyAttached(device: YubiKeyDevice) {
        Log.d(TAG, "Device connected")

        _isUsbKey = device is UsbYubiKeyDevice

        val handler = CoroutineExceptionHandler { _, throwable ->
            Log.e(TAG, "Exception caught: ${throwable.message}")
        }

        coroutineScope.launch(handler) {
            if (pendingYubiKeyAction.value != null) {
                provideYubiKey(com.yubico.yubikit.core.util.Result.success(device))
            } else {
                sendDeviceInfo(device)
                sendOathInfo(device)
                sendOathCodes(device)
            }
        }
    }

    private fun yubikeyDetached() {
        if (_isUsbKey) {
            Log.d(TAG, "Device disconnected")
            // clear keys from memory
            _memoryKeyProvider.clearAll()
            _pendingYubiKeyAction.postValue(null)
            _fManagementApi.updateDeviceInfo("") {}
            _model.reset()
        }
    }

    override fun reset(result: Result<Void>) {
        coroutineScope.launch {
            try {
                useOathSession("Reset YubiKey", true) {
                    // note, it is ok to reset locked session
                    it.reset()
                    _keyManager.removeKey(it.deviceId)
                    returnSuccess(result)
                }
            } catch (e: Throwable) {
                returnError(result, e)
            }
        }
    }

    override fun unlock(
        password: String,
        remember: Boolean,
        result: Result<UnlockResponse>
    ) {
        coroutineScope.launch {
            try {
                var codes: String? = null
                useOathSession("Unlocking", true) {
                    val accessKey = it.deriveAccessKey(password.toCharArray())
                    _keyManager.addKey(it.deviceId, accessKey, remember)

                    val response = UnlockResponse().apply {
                        isUnlocked = tryToUnlockOathSession(it)
                        isRemembered = _keyManager.isRemembered(it.deviceId)
                    }
                    if (response.isUnlocked == true) {
                        _model.update(it.deviceId, calculateOathCodes(it).model(it.deviceId))
                        codes = jsonSerializer.encodeToString(_model.credentials)
                    }
                    returnSuccess(result, response)
                }

                codes?.let {
                    coroutineScope.launch(Dispatchers.Main) {
                        _fOathApi.updateOathCredentials(it) {}
                    }
                }

            } catch (cause: Throwable) {
                returnError(result, cause)
            }
        }
    }

    override fun setPassword(
        currentPassword: String?,
        newPassword: String,
        result: Result<Void>
    ) {
        coroutineScope.launch {
            try {
                useOathSession("Set password", true) { session ->
                    if (session.isAccessKeySet) {
                        if (currentPassword == null) {
                            throw Exception("Must provide current password to be able to change it")
                        }
                        // test current password sent by the user
                        if (!session.unlock(currentPassword.toCharArray())) {
                            throw Exception("Provided current password is invalid")
                        }
                    }
                    val accessKey = session.deriveAccessKey(newPassword.toCharArray())
                    session.setAccessKey(accessKey)
                    _keyManager.addKey(session.deviceId, accessKey, false)
                    Logger.d("Successfully set password")
                    returnSuccess(result)
                }
            } catch (cause: Throwable) {
                returnError(result, cause)
            }
        }
    }

    override fun unsetPassword(currentPassword: String, result: Result<Void>) {
        coroutineScope.launch {
            try {
                useOathSession("Unset password", true) { session ->
                    if (session.isAccessKeySet) {
                        // test current password sent by the user
                        if (session.unlock(currentPassword.toCharArray())) {
                            session.deleteAccessKey()
                            _keyManager.removeKey(session.deviceId)
                            Logger.d("Successfully unset password")
                            returnSuccess(result)
                            return@useOathSession
                        }
                    }
                    returnError(result, Exception("Unset password failed"))
                }
            } catch (cause: Throwable) {
                returnError(result, cause)
            }
        }
    }

    override fun forgetPassword(result: Result<Void>) {
        _keyManager.clearAll()
        Logger.d("Cleared all keys.")
        returnSuccess(result)
    }

    override fun addAccount(
        uri: String,
        requireTouch: Boolean,
        result: Result<String>
    ) {
        coroutineScope.launch {
            try {
                useOathSession("Add account", true) { session ->
                    withUnlockedSession(session) {
                        val credentialData: CredentialData =
                            CredentialData.parseUri(URI.create(uri))

                        val credential = session.putCredential(credentialData, requireTouch)

                        val code =
                            if (credentialData.oathType == OathType.TOTP && !requireTouch) {
                                // recalculate the code
                                calculateCode(session, credential)
                            } else null

                        val addedCred = _model.add(
                            session.deviceId,
                            credential.model(session.deviceId),
                            code?.model()
                        )

                        if (addedCred != null) {
                            val jsonResult = jsonSerializer.encodeToString(addedCred)
                            returnSuccess(result, jsonResult)
                        } else {
                            // TODO - figure out better error handling here
                            returnError(result, java.lang.IllegalStateException())
                        }
                    }
                }
            } catch (cause: Throwable) {
                returnError(result, cause)
            }
        }
    }

    override fun renameAccount(uri: String, name: String, issuer: String?, result: Result<String>) {
        coroutineScope.launch {
            try {
                useOathSession("Rename", true) { session ->
                    withUnlockedSession(session) {
                        val credential = getOathCredential(session, uri)

                        val renamedCredential = _model.rename(
                            it.deviceId,
                            credential.model(it.deviceId),
                            session.renameCredential(credential, name, issuer).model(it.deviceId)
                        )

                        if (renamedCredential != null) {
                            val jsonResult =
                                jsonSerializer.encodeToString(renamedCredential)

                            returnSuccess(result, jsonResult)
                        } else {
                            // TODO - figure out better error handling here
                            returnError(result, java.lang.IllegalStateException())
                        }
                    }
                }
            } catch (cause: Throwable) {
                returnError(result, cause)
            }
        }
    }

    override fun deleteAccount(uri: String, result: Result<Void>) {
        coroutineScope.launch {
            useOathSession("Delete account", true) { session ->
                withUnlockedSession(session) {
                    val credential = getOathCredential(session, uri)
                    session.deleteCredential(credential)
                    returnSuccess(result)
                }
            }
        }
    }

    override fun refreshCodes(result: Result<String>) {
        coroutineScope.launch {
            try {
                if (!_isUsbKey) {
                    throw Exception("Cannot refresh for nfc key")
                }

                useOathSession("Refresh codes", false) {
                    withUnlockedSession(it) { session ->

                        _model.update(
                            session.deviceId,
                            calculateOathCodes(session).model(session.deviceId)
                        )
                        val resultJson = jsonSerializer.encodeToString(_model.credentials)
                        returnSuccess(result, resultJson)
                    }
                }
            } catch (cause: Throwable) {
                returnError(result, cause)
            }
        }
    }

    override fun calculate(uri: String, result: Result<String>) {
        coroutineScope.launch {
            try {
                useOathSession("Calculate", true) {
                    withUnlockedSession(it) { session ->

                        val credential = getOathCredential(session, uri)

                        val code = _model.updateCode(
                            session.deviceId,
                            credential.model(session.deviceId),
                            calculateCode(session, credential).model()
                        )

                        if (code != null) {
                            val resultJson = jsonSerializer.encodeToString(code)

                            returnSuccess(result, resultJson)
                        } else {
                            // TODO - figure out better error handling here
                            returnError(result, java.lang.IllegalStateException())
                        }
                    }
                }
            } catch (cause: Throwable) {
                returnError(result, cause)
            }
        }
    }

    /**
     * Returns Steam code or standard TOTP code based on the credential.
     * @param session OathSession which calculates the TOTP code
     * @param credential
     *
     * @return calculated Code
     */
    private fun calculateCode(
        session: OathSession,
        credential: Credential
    ): Code {
        // Manual calculate, need to pad timer to avoid immediate expiration
        val timestamp = System.currentTimeMillis() + 10000
        return if (credential.isSteamCredential()) {
            session.calculateSteamCode(credential, timestamp)
        } else {
            session.calculateCode(credential, timestamp)
        }
    }

    private suspend fun <T> withSmartCardConnection(
        device: YubiKeyDevice,
        block: (SmartCardConnection) -> T
    ) =
        suspendCoroutine<T> { continuation ->
            device.requestConnection(SmartCardConnection::class.java) {
                if (it.isError) {
                    continuation.resumeWithException(IllegalStateException("Failed to get SmartCardConnection"))
                } else {
                    continuation.resume(block(it.value))
                }
            }
        }

    private suspend fun <T> withOTPConnection(device: YubiKeyDevice, block: (OtpConnection) -> T) =
        suspendCoroutine<T> { continuation ->
            device.requestConnection(OtpConnection::class.java) {
                if (it.isError) {
                    continuation.resumeWithException(IllegalStateException("Failed to get OtpConnection"))
                } else {
                    continuation.resume(block(it.value))
                }
            }
        }

    private suspend fun <T> withFidoConnection(
        device: YubiKeyDevice,
        block: (FidoConnection) -> T
    ) =
        suspendCoroutine<T> { continuation ->
            device.requestConnection(FidoConnection::class.java) {
                if (it.isError) {
                    continuation.resumeWithException(IllegalStateException("Failed to get FidoConnection"))
                } else {
                    continuation.resume(block(it.value))
                }
            }
        }

    private suspend fun getDeviceInfo(device: YubiKeyDevice): AppDeviceInfo =
        try {
            withSmartCardConnection(device) {
                val pid = (device as? UsbYubiKeyDevice)?.pid
                val deviceInfo = DeviceUtil.readInfo(it, pid)
                val name = DeviceUtil.getName(deviceInfo, pid?.type)
                deviceInfo.model(name, device is NfcYubiKeyDevice, pid?.value)
            }
        } catch (exception: Exception) {
            Log.d(TAG, "Smart card connection not available")
            try {
                withOTPConnection(device) {
                    val pid = (device as? UsbYubiKeyDevice)?.pid
                    val deviceInfo = DeviceUtil.readInfo(it, pid)
                    val name = DeviceUtil.getName(deviceInfo, pid?.type)
                    deviceInfo.model(name, device is NfcYubiKeyDevice, pid?.value)
                }
            } catch (exception: Exception) {
                Log.d(TAG, "OTP connection not available")
                try {
                    withFidoConnection(device) {
                        val pid = (device as? UsbYubiKeyDevice)?.pid
                        val deviceInfo = DeviceUtil.readInfo(it, pid)
                        val name = DeviceUtil.getName(deviceInfo, pid?.type)
                        deviceInfo.model(name, device is NfcYubiKeyDevice, pid?.value)
                    }
                } catch (exception: Exception) {
                    Log.e(TAG, "No connection available for getting device info")
                    throw exception
                }
            }
        }

    private suspend fun sendDeviceInfo(device: YubiKeyDevice) {
        val deviceInfoData = getDeviceInfo(device)
        withContext(Dispatchers.Main) {
            Log.d(TAG, "Sending device info: $deviceInfoData")
            _fManagementApi.updateDeviceInfo(Json.encodeToString(deviceInfoData)) {}
        }
    }

    private suspend fun sendOathInfo(device: YubiKeyDevice) {

        val oathSessionData = suspendCoroutine<String> {
            device.requestConnection(SmartCardConnection::class.java) { result ->
                val oathSession = OathSession(result.value)

                val deviceId = oathSession.deviceId

                _previousNfcDeviceId = if (device is NfcYubiKeyDevice) {
                    if (deviceId != _previousNfcDeviceId) {
                        // devices are different, clear access key for previous device
                        _memoryKeyProvider.removeKey(_previousNfcDeviceId)
                    }
                    deviceId
                } else {
                    ""
                }

                // calling unlock session will remove invalid access keys
                tryToUnlockOathSession(oathSession)
                val isRemembered = _keyManager.isRemembered(oathSession.deviceId)

                _model.session = Model.Session(
                    oathSession.deviceId,
                    oathSession.isAccessKeySet,
                    isRemembered,
                    oathSession.isLocked
                )

                val oathSessionData = jsonSerializer.encodeToString(_model.session)
                it.resume(oathSessionData)
            }
        }

        withContext(Dispatchers.Main) {
            _fOathApi.updateSession(oathSessionData) {}
        }
    }

    private suspend fun sendOathCodes(device: YubiKeyDevice) {
        val sendOathCodes = suspendCoroutine<String> {
            device.requestConnection(SmartCardConnection::class.java) { result ->
                val session = OathSession(result.value)
                if (tryToUnlockOathSession(session)) {
                    _model.update(
                        session.deviceId,
                        calculateOathCodes(session).model(session.deviceId)
                    )
                    val resultJson = jsonSerializer.encodeToString(_model.credentials)
                    it.resume(resultJson)
                }
            }
        }

        withContext(Dispatchers.Main) {
            _fOathApi.updateOathCredentials(sendOathCodes) {}
        }
    }

    /**
     * Tries to unlocks [OathSession] with [AccessKey] stored in [KeyManager]. On failure clears
     * relevant access keys from [KeyManager]
     *
     * @return true if we the session is not locked or it was successfully unlocked, false otherwise
     */
    private fun tryToUnlockOathSession(session: OathSession): Boolean {
        if (!session.isLocked) {
            return true
        }

        val deviceId = session.deviceId
        val accessKey = _keyManager.getKey(deviceId)
            ?: return false // we have no access key to unlock the session

        val unlockSucceed = session.unlock(accessKey)

        if (unlockSucceed) {
            return true
        }

        _keyManager.removeKey(deviceId) // remove invalid access keys from [KeyManager]
        return false // the unlock did not work, session is locked
    }

    private fun calculateOathCodes(session: OathSession): Map<Credential, Code> {
        var timestamp = System.currentTimeMillis()
        if (!_isUsbKey) {
            // NFC, need to pad timer to avoid immediate expiration
            timestamp += 10000
        }
        return session.calculateCodes(timestamp).map { (credential, code) ->
            Pair(
                credential, if (credential.isSteamCredential() && !credential.isTouchRequired) {
                    session.calculateSteamCode(credential, timestamp)
                } else {
                    code
                }
            )
        }.toMap()
    }

    private fun <T> withUnlockedSession(session: OathSession, block: (OathSession) -> T): T {
        if (!tryToUnlockOathSession(session)) {
            throw Exception("Session is locked")
        }
        return block(session)
    }

    private suspend fun <T> useOathSession(
        title: String,
        queryUserToTap: Boolean,
        action: (OathSession) -> T
    ) = suspendCoroutine<T> { outer ->
        if (queryUserToTap && !_isUsbKey) {
            dialogManager.showDialog(title) {
                coroutineScope.launch(Dispatchers.Main) {
                    Log.d(TAG, "Cancelled Dialog $title")
                    provideYubiKey(com.yubico.yubikit.core.util.Result.failure(Exception("User canceled")))
                }
            }
        }

        if (_isUsbKey) {
            appViewModel.yubiKeyDevice.value?.let { yubiKey ->
                Log.d(TAG, "Executing action on usb key: $title")
                yubiKey.requestConnection(SmartCardConnection::class.java) {
                    action.invoke(OathSession(it.value))
                }
            } ?: run {
                Log.e(TAG, "USB Key not found for action: $title")
                throw IllegalStateException("USB Key not found for action: $title")
            }
        } else {
            _pendingYubiKeyAction.postValue(YubiKeyAction(title) { yubiKey ->
                outer.resumeWith(runCatching {
                    suspendCoroutine { inner ->
                        yubiKey.value.requestConnection(SmartCardConnection::class.java) {
                            inner.resumeWith(runCatching {
                                action.invoke(OathSession(it.value))
                            })
                        }
                    }
                })
            })
        }
    }

    private fun getOathCredential(oathSession: OathSession, credentialId: String) =
        oathSession.credentials.firstOrNull { credential ->
            (credential != null) && credential.id.asString() == credentialId
        } ?: throw Exception("Failed to find account to delete")


    /// for nfc connection waits for the dialog to be closed and then returns success data
    /// for usb connection returns success data directly
    private fun <T> returnSuccess(result: Result<T>, data: T? = null) {
        coroutineScope.launch(Dispatchers.Main) {
            if (!_isUsbKey) {
                dialogManager.closeDialog {
                    result.success(data)
                }
            } else {
                result.success(data)
            }
        }
    }

    /// for nfc connection waits for the dialog to be closed and then returns error
    /// for usb connection returns error directly
    private fun <T> returnError(result: Result<T>, error: Throwable) {
        coroutineScope.launch(Dispatchers.Main) {
            if (!_isUsbKey) {
                dialogManager.closeDialog {
                    result.error(error)
                }
            } else {
                result.error(error)
            }
        }
    }
}