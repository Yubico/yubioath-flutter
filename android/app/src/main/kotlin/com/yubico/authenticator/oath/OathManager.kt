package com.yubico.authenticator.oath

import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.Observer
import com.yubico.authenticator.*
import com.yubico.authenticator.device.Version
import com.yubico.authenticator.logging.Log
import com.yubico.authenticator.oath.keystore.ClearingMemProvider
import com.yubico.authenticator.oath.keystore.KeyStoreProvider
import com.yubico.authenticator.yubikit.getDeviceInfo
import com.yubico.authenticator.yubikit.withSmartCardConnection
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.oath.*
import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.*
import kotlinx.serialization.encodeToString
import java.net.URI
import java.util.concurrent.Executors
import kotlin.coroutines.suspendCoroutine

class OathManager(
    private val lifecycleOwner: LifecycleOwner,
    messenger: BinaryMessenger,
    appContext: AppContext,
    private val appViewModel: MainViewModel,
    private val dialogManager: DialogManager,
    private val appPreferences: AppPreferences,
) {

    private val _dispatcher = Executors.newSingleThreadExecutor().asCoroutineDispatcher()
    private val coroutineScope = CoroutineScope(SupervisorJob() + _dispatcher)

    private val oathChannel =
        FlutterChannel(messenger, "com.yubico.authenticator.channel.oath")
    private val deviceChannel =
        FlutterChannel(messenger, "com.yubico.authenticator.channel.device")

    private val _memoryKeyProvider = ClearingMemProvider()
    private val _keyManager = KeyManager(KeyStoreProvider(), _memoryKeyProvider)
    private var _previousNfcDeviceId = ""

    private val _pendingYubiKeyAction = MutableLiveData<YubiKeyAction?>()
    private val pendingYubiKeyAction: LiveData<YubiKeyAction?> = _pendingYubiKeyAction

    private val _model = Model()

    init {
        appContext.appContext.observe(lifecycleOwner) {
            if (it == OperationContext.Oath) {
                installObservers()
            } else {
                uninstallObservers()
            }
        }

        // OATH methods callable from Flutter:
        oathChannel.setHandler(coroutineScope) { method, args ->
            when (method) {
                "reset" -> reset()
                "unlock" -> unlock(
                    args["password"] as String,
                    args["remember"] as Boolean
                )
                "setPassword" -> setPassword(
                    args["current"] as String?,
                    args["password"] as String
                )
                "unsetPassword" -> unsetPassword(args["current"] as String)
                "forgetPassword" -> forgetPassword()
                "calculate" -> calculate(args["credentialId"] as String)
                "addAccount" -> addAccount(
                    args["uri"] as String,
                    args["requireTouch"] as Boolean
                )
                "renameAccount" -> renameAccount(
                    args["credentialId"] as String,
                    args["name"] as String,
                    args["issuer"] as String?
                )
                "deleteAccount" -> deleteAccount(args["credentialId"] as String)
                "refreshCodes" -> refreshCodes()
                else -> throw NotImplementedError()
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
        }

    private var _isUsbKey = false
    private fun yubikeyAttached(device: YubiKeyDevice) {
        Log.d(TAG, "Device connected")

        _isUsbKey = device is UsbYubiKeyDevice

        val handler = CoroutineExceptionHandler { _, throwable ->
            Log.e(TAG, "Exception caught: ${throwable.message}")
        }

        coroutineScope.launch(handler) {
            sendDeviceInfo(device)
            readOathData(device)
            if (pendingYubiKeyAction.value != null) {
                provideYubiKey(com.yubico.yubikit.core.util.Result.success(device))
            } else {
                sendOathInfo()
                sendOathCodes()
            }
        }
    }

    private fun yubikeyDetached() {
        if (_isUsbKey) {
            Log.d(TAG, "Device disconnected")
            // clear keys from memory
            _memoryKeyProvider.clearAll()
            _pendingYubiKeyAction.postValue(null)
            coroutineScope.launch {
                deviceChannel.call("setDevice", FlutterChannel.NULL)
            }
            _model.reset()
        }
    }

    private suspend fun reset(): String {
        useOathSession("Reset YubiKey") {
            // note, it is ok to reset locked session
            it.reset()
            _keyManager.removeKey(it.deviceId)
            _model.reset()
            _model.session = Model.Session(
                it.deviceId,
                Version(
                    it.version.major,
                    it.version.minor,
                    it.version.micro
                ),
                isAccessKeySet = false,
                isRemembered = false,
                isLocked = false
            )
        }
        sendOathInfo()
        sendOathCodes()
        return FlutterChannel.NULL
    }


    private suspend fun unlock(password: String, remember: Boolean): String =
        useOathSession("Unlocking") {
            val accessKey = it.deriveAccessKey(password.toCharArray())
            _keyManager.addKey(it.deviceId, accessKey, remember)

            val unlocked = tryToUnlockOathSession(it)
            val remembered = _keyManager.isRemembered(it.deviceId)
            if (unlocked) {
                _model.update(it.deviceId, calculateOathCodes(it).model(it.deviceId))
                coroutineScope.launch {
                    sendOathCodes()
                }
            }

            jsonSerializer.encodeToString(mapOf("unlocked" to unlocked, "remembered" to remembered))
        }

    private suspend fun setPassword(
        currentPassword: String?,
        newPassword: String,
    ): String =
        useOathSession("Set password") { session ->
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
            Log.d(TAG, "Successfully set password")
            FlutterChannel.NULL
        }

    private suspend fun unsetPassword(currentPassword: String): String =
        useOathSession("Unset password") { session ->
            if (session.isAccessKeySet) {
                // test current password sent by the user
                if (session.unlock(currentPassword.toCharArray())) {
                    session.deleteAccessKey()
                    _keyManager.removeKey(session.deviceId)
                    Log.d(TAG, "Successfully unset password")
                    return@useOathSession FlutterChannel.NULL
                }
            }
            throw Exception("Unset password failed")
        }

    private suspend fun forgetPassword(): String {
        _keyManager.clearAll()
        Log.d(TAG, "Cleared all keys.")
        return FlutterChannel.NULL
    }

    private suspend fun addAccount(
        uri: String,
        requireTouch: Boolean,
    ): String =
        useOathSession("Add account") { session ->
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
                    return@withUnlockedSession jsonResult
                } else {
                    // TODO - figure out better error handling here
                    throw java.lang.IllegalStateException()
                }
            }
        }

    private suspend fun renameAccount(uri: String, name: String, issuer: String?): String =
        useOathSession("Rename") { session ->
            withUnlockedSession(session) {
                val credential = getOathCredential(session, uri)

                val renamedCredential = _model.rename(
                    it.deviceId,
                    credential.model(it.deviceId),
                    session.renameCredential(credential, name, issuer).model(it.deviceId)
                )

                if (renamedCredential != null) {
                    return@withUnlockedSession jsonSerializer.encodeToString(renamedCredential)
                } else {
                    // TODO - figure out better error handling here
                    throw java.lang.IllegalStateException()
                }
            }
        }

    private suspend fun deleteAccount(credentialId: String): String =
        useOathSession("Delete account") { session ->
            withUnlockedSession(session) {
                val credential = getOathCredential(session, credentialId)
                session.deleteCredential(credential)
            }
            FlutterChannel.NULL
        }

    private suspend fun refreshCodes(): String {
        if (!_isUsbKey) {
            throw Exception("Cannot refresh for nfc key")
        }

        return useOathSession("Refresh codes") {
            withUnlockedSession(it) { session ->
                _model.update(
                    session.deviceId,
                    calculateOathCodes(session).model(session.deviceId)
                )
                jsonSerializer.encodeToString(_model.credentials)
            }
        }
    }

    private suspend fun calculate(credentialId: String): String =
        useOathSession("Calculate") {
            withUnlockedSession(it) { session ->
                val credential = getOathCredential(session, credentialId)

                val code = _model.updateCode(
                    session.deviceId,
                    credential.model(session.deviceId),
                    calculateCode(session, credential).model()
                )
                Log.d(TAG, "Code calculated $code")

                if (code != null) {
                    return@withUnlockedSession jsonSerializer.encodeToString(code)
                } else {
                    // TODO - figure out better error handling here
                    throw java.lang.IllegalStateException()
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

    private suspend fun sendDeviceInfo(device: YubiKeyDevice) {
        val deviceInfoData = getDeviceInfo(device)
        Log.d(TAG, "Sending device info: $deviceInfoData")
        deviceChannel.call("setDevice", jsonSerializer.encodeToString(deviceInfoData))
        Log.d(TAG, "Device info sent successfully")
    }


    private suspend fun readOathData(device: YubiKeyDevice) {
        withSmartCardConnection(device) { smartCardConnection ->
            val oathSession = OathSession(smartCardConnection)

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
            val isUnlocked = tryToUnlockOathSession(oathSession)
            val isRemembered = _keyManager.isRemembered(deviceId)

            _model.session = Model.Session(
                deviceId,
                Version(
                    oathSession.version.major,
                    oathSession.version.minor,
                    oathSession.version.micro
                ),
                oathSession.isAccessKeySet,
                isRemembered,
                oathSession.isLocked
            )

            if (isUnlocked) {
                _model.update(
                    deviceId,
                    calculateOathCodes(oathSession).model(deviceId)
                )
            }

            Log.d(TAG, "Successfully read Oath session info (and credentials if unlocked) from connected key")
        }
    }

    private suspend fun sendOathInfo() {
        val oathSessionData = jsonSerializer.encodeToString(_model.session)
        oathChannel.call("setState", oathSessionData)
        Log.d(TAG, "OathSessionData sent successfully")
    }

    private suspend fun sendOathCodes() {
        val sendOathCodes = jsonSerializer.encodeToString(_model.credentials)
        oathChannel.call("setCredentials", sendOathCodes)
        Log.d(TAG, "OathCredentials sent successfully")
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
        val bypassTouch = appPreferences.bypassTouchOnNfcTap && !_isUsbKey
        return session.calculateCodes(timestamp).map { (credential, code) ->
            Pair(
                credential, if (credential.isSteamCredential() && (!credential.isTouchRequired || bypassTouch)) {
                    session.calculateSteamCode(credential, timestamp)
                } else if (credential.isTouchRequired && bypassTouch) {
                    session.calculateCode(credential, timestamp)
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

    private suspend fun <T> useOathSessionUsb(
        title: String,
        action: (OathSession) -> T
    ): T {
        return suspendCoroutine { outer ->
            appViewModel.yubiKeyDevice.value?.let { yubiKey ->
                Log.d(TAG, "Executing action on usb key: $title")
                yubiKey.requestConnection(SmartCardConnection::class.java) {
                    outer.resumeWith(runCatching {
                        action.invoke(OathSession(it.value))
                    })
                }
            } ?: run {
                Log.e(TAG, "USB Key not found for action: $title")
                throw IllegalStateException("USB Key not found for action: $title")
            }
        }
    }

    private suspend fun <T> useOathSessionNfc(
        title: String,
        action: (OathSession) -> T
    ): T {
        try {
            val result = suspendCoroutine { outer ->
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
                dialogManager.showDialog(Icon.NFC, "Tap your key", title) {
                    Log.d(TAG, "Cancelled Dialog $title")
                    provideYubiKey(
                        com.yubico.yubikit.core.util.Result.failure(
                            CancellationException()
                        )
                    )
                }
            }
            dialogManager.updateDialogState(
                icon = Icon.SUCCESS,
                title = "Success"
            )
            // TODO: This delays the closing of the dialog, but also the return value
            delay(500)
            return result
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (error: Throwable) {
            dialogManager.updateDialogState(
                icon = Icon.ERROR,
                title = "Failure",
                description = "Action failed - try again"
            )
            // TODO: This delays the closing of the dialog, but also the return value
            delay(1500)
            throw error
        } finally {
            dialogManager.closeDialog()
        }
    }

    private suspend fun <T> useOathSession(
        title: String,
        action: (OathSession) -> T
    ): T {
        return if (_isUsbKey) {
            // Uses the connected YubiKey directly
            useOathSessionUsb(title, action)
        } else {
            // Prompts for NFC tap
            useOathSessionNfc(title, action)
        }
    }

    private fun getOathCredential(oathSession: OathSession, credentialId: String) =
        oathSession.credentials.firstOrNull { credential ->
            (credential != null) && credential.id.asString() == credentialId
        } ?: throw Exception("Failed to find account to delete")
}