/*
 * Copyright (C) 2022-2023 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.yubico.authenticator.oath

import android.annotation.TargetApi
import android.content.Context
import android.os.Build
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import com.yubico.authenticator.*
import com.yubico.authenticator.device.Capabilities
import com.yubico.authenticator.device.Info
import com.yubico.authenticator.device.UnknownDevice
import com.yubico.authenticator.logging.Log
import com.yubico.authenticator.oath.data.Code
import com.yubico.authenticator.oath.data.CodeType
import com.yubico.authenticator.oath.data.Credential
import com.yubico.authenticator.oath.data.CredentialWithCode
import com.yubico.authenticator.oath.data.Session
import com.yubico.authenticator.oath.data.YubiKitCode
import com.yubico.authenticator.oath.data.YubiKitCredential
import com.yubico.authenticator.oath.data.YubiKitOathSession
import com.yubico.authenticator.oath.data.YubiKitOathType
import com.yubico.authenticator.oath.data.calculateSteamCode
import com.yubico.authenticator.oath.data.isSteamCredential
import com.yubico.authenticator.oath.keystore.ClearingMemProvider
import com.yubico.authenticator.oath.keystore.KeyProvider
import com.yubico.authenticator.oath.keystore.KeyStoreProvider
import com.yubico.authenticator.oath.keystore.SharedPrefProvider
import com.yubico.authenticator.yubikit.getDeviceInfo
import com.yubico.authenticator.yubikit.withConnection
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.Transport
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.application.ApplicationNotAvailableException
import com.yubico.yubikit.core.smartcard.ApduException
import com.yubico.yubikit.core.smartcard.SW
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.smartcard.SmartCardProtocol
import com.yubico.yubikit.core.util.Result
import com.yubico.yubikit.oath.CredentialData
import com.yubico.yubikit.support.DeviceUtil
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import kotlinx.serialization.encodeToString
import java.net.URI
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.coroutines.suspendCoroutine

typealias OathAction = (Result<YubiKitOathSession, Exception>) -> Unit

class OathManager(
    private val lifecycleOwner: LifecycleOwner,
    messenger: BinaryMessenger,
    private val appViewModel: MainViewModel,
    private val oathViewModel: OathViewModel,
    private val dialogManager: DialogManager,
    private val appPreferences: AppPreferences,
) : AppContextManager {
    companion object {
        const val TAG = "OathManager"
        const val NFC_DATA_CLEANUP_DELAY = 30L * 1000 // 30s
        val OTP_AID = byteArrayOf(0xa0.toByte(), 0x00, 0x00, 0x05, 0x27, 0x20, 0x01, 0x01)
    }

    private val dispatcher = Executors.newSingleThreadExecutor().asCoroutineDispatcher()
    private val coroutineScope = CoroutineScope(SupervisorJob() + dispatcher)

    private val oathChannel = MethodChannel(messenger, "android.oath.methods")

    private val memoryKeyProvider = ClearingMemProvider()
    private val keyManager by lazy {
        KeyManager(
            compatUtil.from(Build.VERSION_CODES.M) {
                createKeyStoreProviderM()
            }.otherwise(
                SharedPrefProvider(lifecycleOwner as Context)
            ), memoryKeyProvider
        )
    }

    @TargetApi(Build.VERSION_CODES.M)
    private fun createKeyStoreProviderM(): KeyProvider = KeyStoreProvider()

    private val unlockOnConnect = AtomicBoolean(true)
    private var pendingAction: OathAction? = null
    private var refreshJob: Job? = null
    private var addToAny = false

    // provides actions for lifecycle events
    private val lifecycleObserver = object : DefaultLifecycleObserver {

        private var startTimeMs: Long = -1

        override fun onPause(owner: LifecycleOwner) {
            startTimeMs = currentTimeMs

            // cancel any pending actions, except for addToAny
            if (!addToAny) {
                pendingAction?.let {
                    Log.d(TAG, "Cancelling pending action/closing nfc dialog.")
                    it.invoke(Result.failure(CancellationException()))
                    coroutineScope.launch {
                        dialogManager.closeDialog()
                    }
                    pendingAction = null
                }
            }

            super.onPause(owner)
        }

        override fun onResume(owner: LifecycleOwner) {
            super.onResume(owner)
            if (canInvoke) {
                if (appViewModel.connectedYubiKey.value == null) {
                    // no USB YubiKey is connected, reset known data on resume
                    Log.d(TAG, "Removing NFC data after resume.")
                    appViewModel.setDeviceInfo(null)
                    oathViewModel.setSessionState(null)
                }
            }
        }


        private val currentTimeMs
            get() = System.currentTimeMillis()

        private val canInvoke: Boolean
            get() = startTimeMs != -1L && currentTimeMs - startTimeMs > NFC_DATA_CLEANUP_DELAY
    }

    private val usbObserver = Observer<UsbYubiKeyDevice?> {
        refreshJob?.cancel()
        if (it == null) {
            appViewModel.setDeviceInfo(null)
            oathViewModel.setSessionState(null)
        }
    }

    private val credentialObserver = Observer<List<CredentialWithCode>?> { codes ->
        refreshJob?.cancel()
        if (codes != null && appViewModel.connectedYubiKey.value != null) {
            val expirations = codes
                .filter { it.credential.codeType == CodeType.TOTP && !it.credential.touchRequired }
                .mapNotNull { it.code?.validTo }
            if (expirations.isNotEmpty()) {
                val earliest = expirations.min() * 1000
                val now = System.currentTimeMillis()

                refreshJob = coroutineScope.launch {
                    val delayMs = earliest - now
                    Log.d(TAG, "Will execute refresh in ${delayMs}ms")
                    if (delayMs > 0) {
                        delay(delayMs)
                    }
                    val currentState = lifecycleOwner.lifecycle.currentState
                    if (currentState.isAtLeast(Lifecycle.State.RESUMED)) {
                        requestRefresh()
                    } else {
                        Log.d(
                            TAG,
                            "Cannot run credential refresh in current lifecycle state: $currentState"
                        )
                    }
                }
            }
        }
    }

    init {
        appViewModel.connectedYubiKey.observe(lifecycleOwner, usbObserver)
        oathViewModel.credentials.observe(lifecycleOwner, credentialObserver)

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
                "addAccountToAny" -> addAccountToAny(
                    args["uri"] as String,
                    args["requireTouch"] as Boolean
                )

                else -> throw NotImplementedError()
            }
        }

        lifecycleOwner.lifecycle.addObserver(lifecycleObserver)
    }

    override fun dispose() {
        lifecycleOwner.lifecycle.removeObserver(lifecycleObserver)
        appViewModel.connectedYubiKey.removeObserver(usbObserver)
        oathViewModel.credentials.removeObserver(credentialObserver)
        oathChannel.setMethodCallHandler(null)
        coroutineScope.cancel()
    }

    override suspend fun processYubiKey(device: YubiKeyDevice) {
        try {
            device.withConnection<SmartCardConnection, Unit> { connection ->
                val session = getOathSession(connection)
                val previousId = oathViewModel.sessionState.value?.deviceId
                if (session.deviceId == previousId && device is NfcYubiKeyDevice) {
                    // Run any pending action
                    pendingAction?.let { action ->
                        action.invoke(Result.success(session))
                        pendingAction = null
                    }

                    // Refresh codes
                    if (!session.isLocked) {
                        try {
                            oathViewModel.updateCredentials(calculateOathCodes(session))
                        } catch (error: Exception) {
                            Log.e(TAG, "Failed to refresh codes", error.toString())
                        }
                    }
                } else {
                    // Clear in-memory password for any previous device
                    if (connection.transport == Transport.NFC && previousId != null) {
                        memoryKeyProvider.removeKey(previousId)
                    }

                    // Update the OATH state
                    oathViewModel.setSessionState(
                        Session(
                            session,
                            keyManager.isRemembered(session.deviceId)
                        )
                    )
                    if (!session.isLocked) {
                        oathViewModel.updateCredentials(calculateOathCodes(session))
                    }

                    // Awaiting an action for a different or no device?
                    pendingAction?.let { action ->
                        pendingAction = null
                        if (addToAny) {
                            // Special "add to any YubiKey" action, process
                            addToAny = false
                            action.invoke(Result.success(session))
                        } else {
                            // Awaiting an action for a different device? Fail it and stop processing.
                            action.invoke(Result.failure(IllegalStateException("Wrong deviceId")))
                            return@withConnection
                        }
                    }

                    if (session.version.isLessThan(4, 0, 0) && connection.transport == Transport.NFC) {
                        // NEO over NFC, select OTP applet before reading info
                        try {
                            SmartCardProtocol(connection).select(OTP_AID)
                        } catch (e: Exception) {
                            Log.e(TAG, "Failed to recognize this OATH device.")
                            // we know this is NFC device and it supports OATH
                            val oathCapabilities = Capabilities(nfc = 0x20)
                            appViewModel.setDeviceInfo(
                                UnknownDevice.copy(
                                    config = UnknownDevice.config.copy(enabledCapabilities = oathCapabilities),
                                    name = "Unknown OATH device",
                                    isNfc = true,
                                    supportedCapabilities = oathCapabilities
                                )
                            )
                            return@withConnection
                        }
                    }

                    // Update deviceInfo since the deviceId has changed
                    val pid = (device as? UsbYubiKeyDevice)?.pid
                    val deviceInfo = DeviceUtil.readInfo(connection, pid)
                    appViewModel.setDeviceInfo(
                        Info(
                            name = DeviceUtil.getName(deviceInfo, pid?.type),
                            isNfc = device.transport == Transport.NFC,
                            usbPid = pid?.value,
                            deviceInfo = deviceInfo
                        )
                    )

                }
            }
            Log.d(
                TAG,
                "Successfully read Oath session info (and credentials if unlocked) from connected key"
            )
        } catch (e: Exception) {
            // OATH not enabled/supported, try to get DeviceInfo over other USB interfaces
            Log.e(TAG, "Failed to connect to CCID", e.toString())
            if (device.transport == Transport.USB || e is ApplicationNotAvailableException) {
                val deviceInfo = try {
                    getDeviceInfo(device)
                } catch (e: IllegalArgumentException) {
                    Log.d(TAG, "Device was not recognized")
                    UnknownDevice.copy(isNfc = device.transport == Transport.NFC)
                } catch (e: Exception) {
                    Log.d(TAG, "Failure getting device info: ${e.message}")
                    null
                }

                Log.d(TAG, "Setting device info: $deviceInfo")
                appViewModel.setDeviceInfo(deviceInfo)
            }

            // Clear any cached OATH state
            oathViewModel.setSessionState(null)
        }
    }

    private suspend fun addAccountToAny(
        uri: String,
        requireTouch: Boolean,
    ): String {
        val credentialData: CredentialData =
            CredentialData.parseUri(URI.create(uri))
        addToAny = true
        return useOathSessionNfc("Add account") { session ->
            // We need to check for duplicates here since we haven't yet read the credentials
            if (session.credentials.any { it.id.contentEquals(credentialData.id) }) {
                throw Exception("A credential with this ID already exists!")
            }

            val credential = session.putCredential(credentialData, requireTouch)
            val code =
                if (credentialData.oathType == YubiKitOathType.TOTP && !requireTouch) {
                    // recalculate the code
                    calculateCode(session, credential)
                } else null

            val addedCred = oathViewModel.addCredential(
                Credential(credential, session.deviceId),
                Code.from(code)
            )

            Log.d(TAG, "Added cred $credential")
            jsonSerializer.encodeToString(addedCred)
        }
    }

    private suspend fun reset(): String =
        useOathSession("Reset YubiKey") {
            // note, it is ok to reset locked session
            it.reset()
            keyManager.removeKey(it.deviceId)
            oathViewModel.resetOathSession(
                Session(it, false),
                calculateOathCodes(it)
            )
            NULL
        }

    private suspend fun unlock(password: String, remember: Boolean): String =
        useOathSession("Unlocking") {
            val accessKey = it.deriveAccessKey(password.toCharArray())
            keyManager.addKey(it.deviceId, accessKey, remember)

            val unlocked = tryToUnlockOathSession(it)
            val remembered = keyManager.isRemembered(it.deviceId)
            if (unlocked) {
                oathViewModel.setSessionState(Session(it, remembered))

                // fetch credentials after unlocking only if the YubiKey is connected over USB
                if ( appViewModel.connectedYubiKey.value != null) {
                    oathViewModel.updateCredentials(calculateOathCodes(it))
                }
            }

            jsonSerializer.encodeToString(mapOf("unlocked" to unlocked, "remembered" to remembered))
        }

    private suspend fun setPassword(
        currentPassword: String?,
        newPassword: String,
    ): String =
        useOathSession("Set password", unlock = false) { session ->
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
            keyManager.addKey(session.deviceId, accessKey, false)
            oathViewModel.setSessionState(Session(session, false))
            Log.d(TAG, "Successfully set password")
            NULL
        }

    private suspend fun unsetPassword(currentPassword: String): String =
        useOathSession("Unset password", unlock = false) { session ->
            if (session.isAccessKeySet) {
                // test current password sent by the user
                if (session.unlock(currentPassword.toCharArray())) {
                    session.deleteAccessKey()
                    keyManager.removeKey(session.deviceId)
                    oathViewModel.setSessionState(Session(session, false))
                    Log.d(TAG, "Successfully unset password")
                    return@useOathSession NULL
                }
            }
            throw Exception("Unset password failed")
        }

    private suspend fun forgetPassword(): String {
        keyManager.clearAll()
        Log.d(TAG, "Cleared all keys.")
        oathViewModel.sessionState.value?.let {
            oathViewModel.setSessionState(
                it.copy(
                    isLocked = it.isAccessKeySet,
                    isRemembered = false
                )
            )
        }
        return NULL
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
                if (credentialData.oathType == YubiKitOathType.TOTP && !requireTouch) {
                    // recalculate the code
                    calculateCode(session, credential)
                } else null

            val addedCred = oathViewModel.addCredential(
                Credential(credential, session.deviceId),
                Code.from(code)
            )

            jsonSerializer.encodeToString(addedCred)
        }

    private suspend fun renameAccount(uri: String, name: String, issuer: String?): String =
        useOathSession("Rename") { session ->
            val credential = getOathCredential(session, uri)
            val renamedCredential =
                Credential(session.renameCredential(credential, name, issuer), session.deviceId)
            oathViewModel.renameCredential(
                Credential(credential, session.deviceId),
                renamedCredential
            )

            jsonSerializer.encodeToString(renamedCredential)
        }

    private suspend fun deleteAccount(credentialId: String): String =
        useOathSession("Delete account") { session ->
            val credential = getOathCredential(session, credentialId)
            session.deleteCredential(credential)
            oathViewModel.removeCredential(Credential(credential, session.deviceId))
            NULL
        }

    private suspend fun requestRefresh() =
        appViewModel.connectedYubiKey.value?.let { usbYubiKeyDevice ->
            useOathSessionUsb(usbYubiKeyDevice) { session ->
                try {
                    oathViewModel.updateCredentials(calculateOathCodes(session))
                } catch (apduException: ApduException) {
                    if (apduException.sw == SW.SECURITY_CONDITION_NOT_SATISFIED) {
                        Log.d(TAG, "Handled oath credential refresh on locked session.")
                        oathViewModel.setSessionState(
                            Session(
                                session,
                                keyManager.isRemembered(session.deviceId)
                            )
                        )
                    } else {
                        Log.e(
                            TAG,
                            "Unexpected sw when refreshing oath credentials",
                            apduException.message
                        )
                    }
                }
            }
        }

    private suspend fun calculate(credentialId: String): String =
        useOathSession("Calculate") { session ->
            val credential = getOathCredential(session, credentialId)

            val code = Code.from(calculateCode(session, credential))
            oathViewModel.updateCode(
                Credential(credential, session.deviceId),
                code
            )
            Log.d(TAG, "Code calculated $code")

            jsonSerializer.encodeToString(code)
        }

    /**
     * Returns Steam code or standard TOTP code based on the credential.
     * @param session YubiKitOathSession which calculates the TOTP code
     * @param credential
     *
     * @return calculated Code
     */
    private fun calculateCode(
        session: YubiKitOathSession,
        credential: YubiKitCredential
    ): YubiKitCode {
        // Manual calculate, need to pad timer to avoid immediate expiration
        val timestamp = System.currentTimeMillis() + 10000
        try {
            return if (credential.isSteamCredential()) {
                session.calculateSteamCode(credential, timestamp)
            } else {
                session.calculateCode(credential, timestamp)
            }
        } catch (apduException: ApduException) {
            if (credential.isTouchRequired && apduException.sw == SW.SECURITY_CONDITION_NOT_SATISFIED) {
                // the most probable reason for this exception
                // is that the user did not touch the key
                throw CancellationException()
            }
            throw apduException
        }
    }

    /**
     * Tries to unlocks [session] with access key stored in [KeyManager]. On failure clears
     * relevant access keys from [KeyManager]
     *
     * @return true if the session is not locked or it was successfully unlocked, false otherwise
     */
    private fun tryToUnlockOathSession(session: YubiKitOathSession): Boolean {
        if (!session.isLocked) {
            return true
        }

        val deviceId = session.deviceId
        val accessKey = keyManager.getKey(deviceId)
            ?: return false // we have no access key to unlock the session

        val unlockSucceed = session.unlock(accessKey)

        if (unlockSucceed) {
            return true
        }

        keyManager.removeKey(deviceId) // remove invalid access keys from [KeyManager]
        return false // the unlock did not work, session is locked
    }

    /**
     * Returns a [YubiKitOathSession] for the [connection].
     * The session will be unlocked if [unlockOnConnect] is true.
     *
     * Generally we always want to try to unlock the session and that is why the variable
     * [unlockOnConnect] is also reset to true.
     *
     * Currently, only setPassword and unsetPassword will not unlock the session.
     *
     * @param connection the device SmartCard connection
     * @return a [YubiKitOathSession]  which is unlocked or locked based on an internal parameter
     */
    private fun getOathSession(connection: SmartCardConnection) : YubiKitOathSession {
        val session = YubiKitOathSession(connection)

        if (!unlockOnConnect.compareAndSet(false, true)) {
            tryToUnlockOathSession(session)
        }

        return session
    }


    private fun calculateOathCodes(session: YubiKitOathSession): Map<Credential, Code?> {
        val isUsbKey = appViewModel.connectedYubiKey.value != null
        var timestamp = System.currentTimeMillis()
        if (!isUsbKey) {
            // NFC, need to pad timer to avoid immediate expiration
            timestamp += 10000
        }
        val bypassTouch = appPreferences.bypassTouchOnNfcTap && !isUsbKey
        return session.calculateCodes(timestamp).map { (credential, code) ->
            Pair(
                Credential(credential, session.deviceId),
                Code.from(if (credential.isSteamCredential() && (!credential.isTouchRequired || bypassTouch)) {
                    session.calculateSteamCode(credential, timestamp)
                } else if (credential.isTouchRequired && bypassTouch) {
                    session.calculateCode(credential, timestamp)
                } else {
                    code
                })
            )
        }.toMap()
    }

    private suspend fun <T> useOathSession(
        title: String,
        unlock: Boolean = true,
        action: (YubiKitOathSession) -> T
    ): T {

        // callers can decide whether the session should be unlocked first
        unlockOnConnect.set(unlock)
        return appViewModel.connectedYubiKey.value?.let {
            useOathSessionUsb(it, action)
        } ?: useOathSessionNfc(title, action)
    }

    private suspend fun <T> useOathSessionUsb(
        device: UsbYubiKeyDevice,
        block: (YubiKitOathSession) -> T
    ): T = device.withConnection<SmartCardConnection, T> {
        block(getOathSession(it))
    }

    private suspend fun <T> useOathSessionNfc(
        title: String,
        block: (YubiKitOathSession) -> T
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

    private fun getOathCredential(session: YubiKitOathSession, credentialId: String) =
        // we need to use oathSession.calculateCodes() to get proper Credential.touchRequired value
        session.calculateCodes().map { e -> e.key }.firstOrNull { credential ->
            (credential != null) && credential.id.asString() == credentialId
        } ?: throw Exception("Failed to find account")


}