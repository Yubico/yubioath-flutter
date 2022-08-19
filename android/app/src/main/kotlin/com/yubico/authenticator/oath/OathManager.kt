package com.yubico.authenticator.oath

import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import com.yubico.authenticator.*
import com.yubico.authenticator.logging.Log
import com.yubico.authenticator.management.model
import com.yubico.authenticator.oath.keystore.ClearingMemProvider
import com.yubico.authenticator.oath.keystore.KeyStoreProvider
import com.yubico.authenticator.yubikit.getDeviceInfo
import com.yubico.authenticator.yubikit.withConnection
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.Transport
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.application.ApplicationNotAvailableException
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.util.Result
import com.yubico.yubikit.oath.*
import com.yubico.yubikit.support.DeviceUtil
import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.*
import kotlinx.serialization.encodeToString
import java.net.URI
import java.util.concurrent.Executors
import kotlin.coroutines.suspendCoroutine

typealias OathAction = (Result<OathSession, Exception>) -> Unit

class OathManager(
    private val lifecycleOwner: LifecycleOwner,
    messenger: BinaryMessenger,
    appContext: AppContext,
    private val appViewModel: MainViewModel,
    private val oathViewModel: OathViewModel,
    private val dialogManager: DialogManager,
    private val appPreferences: AppPreferences,
) {

    private val _dispatcher = Executors.newSingleThreadExecutor().asCoroutineDispatcher()
    private val coroutineScope = CoroutineScope(SupervisorJob() + _dispatcher)

    private val oathChannel = FlutterChannel(messenger, "android.oath.methods")

    private val _memoryKeyProvider = ClearingMemProvider()
    private val _keyManager = KeyManager(KeyStoreProvider(), _memoryKeyProvider)

    private var pendingAction: OathAction? = null

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
                "requestRefresh" -> requestRefresh()
                else -> throw NotImplementedError()
            }
        }
    }

    companion object {
        const val TAG = "OathManager"
    }

    private val deviceObserver =
        Observer<YubiKeyDevice?> { yubiKeyDevice ->
            try {
                if (yubiKeyDevice != null) {
                    yubikeyAttached(yubiKeyDevice)
                } else {
                    yubikeyDetached()
                }
            } catch (e: Throwable) {
                Log.e(TAG, "Error in device observer", e.toString())
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

    private var _isUsbKey = false

    private fun yubikeyAttached(device: YubiKeyDevice) {
        _isUsbKey = device.transport == Transport.USB
        coroutineScope.launch {
            try {
                device.withConnection<SmartCardConnection, Unit> {
                    val oath = OathSession(it)
                    tryToUnlockOathSession(oath)

                    val previousId = oathViewModel.sessionState.value?.deviceId
                    if (oath.deviceId == previousId) {
                        // Run any pending action
                        pendingAction?.let { action ->
                            action.invoke(Result.success(oath))
                            pendingAction = null
                        }

                        // Refresh codes
                        if (!oath.isLocked) {
                            try {
                                oathViewModel.updateCredentials(
                                    calculateOathCodes(oath).model(oath.deviceId)
                                )
                            } catch (error: Exception) {
                                Log.e(TAG, "Failed to refresh codes", error.toString())
                            }
                        }
                    } else {
                        // Awaiting an action for a different device? Fail it and stop processing.
                        pendingAction?.let { action ->
                            action.invoke(Result.failure(IllegalStateException("Wrong deviceId")))
                            pendingAction = null
                            return@withConnection
                        }

                        // Clear in-memory password for any previous device
                        if (it.transport == Transport.NFC && previousId != null) {
                            _memoryKeyProvider.removeKey(previousId)
                        }

                        // Update the OATH state
                        oathViewModel.setSessionState(oath.model(_keyManager.isRemembered(oath.deviceId)))
                        if(!oath.isLocked) {
                            oathViewModel.updateCredentials(
                                calculateOathCodes(oath).model(oath.deviceId)
                            )
                        }

                        // Update deviceInfo since the deviceId has changed
                        val pid = (device as? UsbYubiKeyDevice)?.pid
                        val deviceInfo = DeviceUtil.readInfo(it, pid)
                        appViewModel.setDeviceInfo(deviceInfo.model(
                            DeviceUtil.getName(deviceInfo, pid?.type),
                            device.transport == Transport.NFC,
                            pid?.value
                        ))
                    }
                }
                Log.d(TAG, "Successfully read Oath session info (and credentials if unlocked) from connected key")
            } catch (e: Exception) {
                // OATH not enabled/supported, try to get DeviceInfo over other USB interfaces
                Log.e(TAG, "Failed to connect to CCID", e.toString())
                if (device.transport == Transport.USB || e is ApplicationNotAvailableException) {
                    val deviceInfoData = getDeviceInfo(device)
                    Log.d(TAG, "Sending device info: $deviceInfoData")
                    appViewModel.setDeviceInfo(deviceInfoData)
                }

                // Clear any cached OATH state
                oathViewModel.setSessionState(null)
            }
        }
    }

    private fun yubikeyDetached() {
        if (_isUsbKey) {
            Log.d(TAG, "Device disconnected")
            // clear keys from memory
            _memoryKeyProvider.clearAll()
            pendingAction = null
            appViewModel.setDeviceInfo(null)
            oathViewModel.setSessionState(null)
        }
    }

    private suspend fun reset(): String {
        useOathSession("Reset YubiKey") {
            // note, it is ok to reset locked session
            it.reset()
            _keyManager.removeKey(it.deviceId)
            oathViewModel.setSessionState(it.model(false))
        }
        return FlutterChannel.NULL
    }


    private suspend fun unlock(password: String, remember: Boolean): String =
        useOathSession("Unlocking") {
            val accessKey = it.deriveAccessKey(password.toCharArray())
            _keyManager.addKey(it.deviceId, accessKey, remember)

            val unlocked = tryToUnlockOathSession(it)
            val remembered = _keyManager.isRemembered(it.deviceId)
            if (unlocked) {
                oathViewModel.setSessionState(it.model(remembered))
                oathViewModel.updateCredentials(calculateOathCodes(it).model(it.deviceId))
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
            oathViewModel.setSessionState(session.model(false))
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
                    oathViewModel.setSessionState(session.model(false))
                    Log.d(TAG, "Successfully unset password")
                    return@useOathSession FlutterChannel.NULL
                }
            }
            throw Exception("Unset password failed")
        }

    private suspend fun forgetPassword(): String {
        _keyManager.clearAll()
        Log.d(TAG, "Cleared all keys.")
        oathViewModel.sessionState.value?.let {
            oathViewModel.setSessionState(it.copy(isLocked = it.isAccessKeySet, isRemembered = false))
        }
        return FlutterChannel.NULL
    }

    private suspend fun addAccount(
        uri: String,
        requireTouch: Boolean,
    ): String =
        useOathSession("Add account") { session ->
            val credentialData: CredentialData =
                CredentialData.parseUri(URI.create(uri))

            val credential = session.putCredential(credentialData, requireTouch)

            val code =
                if (credentialData.oathType == OathType.TOTP && !requireTouch) {
                    // recalculate the code
                    calculateCode(session, credential)
                } else null

            val addedCred = oathViewModel.addCredential(
                credential.model(session.deviceId),
                code?.model()
            )

            jsonSerializer.encodeToString(addedCred)
        }

    private suspend fun renameAccount(uri: String, name: String, issuer: String?): String =
        useOathSession("Rename") { session ->
            val credential = getOathCredential(session, uri)
            val renamedCredential = session.renameCredential(credential, name, issuer).model(session.deviceId)
            oathViewModel.renameCredential(
                credential.model(session.deviceId),
                renamedCredential
            )

            jsonSerializer.encodeToString(renamedCredential)
        }

    private suspend fun deleteAccount(credentialId: String): String =
        useOathSession("Delete account") { session ->
            val credential = getOathCredential(session, credentialId)
            session.deleteCredential(credential)
            oathViewModel.removeCredential(credential.model(session.deviceId))
            FlutterChannel.NULL
        }

    private suspend fun requestRefresh(): String {
        if (!_isUsbKey) {
            throw IllegalStateException("Cannot refresh for nfc key")
        }

        return useOathSession("Refresh codes") { session ->
            oathViewModel.updateCredentials(
                calculateOathCodes(session).model(session.deviceId)
            )
            FlutterChannel.NULL
        }
    }

    private suspend fun calculate(credentialId: String): String =
        useOathSession("Calculate") { session ->
            val credential = getOathCredential(session, credentialId)

            val code = calculateCode(session, credential).model()
            oathViewModel.updateCode(
                credential.model(session.deviceId),
                code
            )
            Log.d(TAG, "Code calculated $code")

            jsonSerializer.encodeToString(code)
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

    private suspend fun <T> useOathSessionUsb(
        title: String,
        action: (OathSession) -> T
    ): T {
        appViewModel.yubiKeyDevice.value?.let { yubiKey ->
            Log.d(TAG, "Executing action on usb key: $title")
            return yubiKey.withConnection<SmartCardConnection, T> {
                action.invoke(OathSession(it))
            }
        }

        Log.e(TAG, "USB Key not found for action: $title")
        throw IllegalStateException("USB Key not found for action: $title")
    }

    private suspend fun <T> useOathSessionNfc(
        title: String,
        block: (OathSession) -> T
    ): T {
        try {
            val result = suspendCoroutine { outer ->
                pendingAction = {
                    outer.resumeWith(runCatching {
                        block.invoke(it.value)
                    })
                }
                dialogManager.showDialog(Icon.NFC, "Tap your key", title) {
                    Log.d(TAG, "Cancelled Dialog $title")
                    pendingAction?.invoke(Result.failure(CancellationException()))
                    pendingAction = null
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
        } ?: throw Exception("Failed to find account")
}