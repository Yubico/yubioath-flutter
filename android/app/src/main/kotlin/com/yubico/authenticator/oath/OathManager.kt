/*
 * Copyright (C) 2022-2024 Yubico.
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
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import com.yubico.authenticator.*
import com.yubico.authenticator.device.Capabilities
import com.yubico.authenticator.device.DeviceListener
import com.yubico.authenticator.device.DeviceManager
import com.yubico.authenticator.device.UnknownDevice
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
import com.yubico.authenticator.yubikit.DeviceInfoHelper.Companion.getDeviceInfo
import com.yubico.authenticator.yubikit.withConnection
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.Transport
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.smartcard.ApduException
import com.yubico.yubikit.core.smartcard.AppId
import com.yubico.yubikit.core.smartcard.SW
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.smartcard.SmartCardProtocol
import com.yubico.yubikit.core.util.Result
import com.yubico.yubikit.management.Capability
import com.yubico.yubikit.oath.CredentialData
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import kotlinx.serialization.encodeToString
import org.slf4j.LoggerFactory
import java.io.IOException
import java.net.URI
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.coroutines.suspendCoroutine

typealias OathAction = (Result<YubiKitOathSession, Exception>) -> Unit

class OathManager(
    private val lifecycleOwner: LifecycleOwner,
    messenger: BinaryMessenger,
    private val deviceManager: DeviceManager,
    private val oathViewModel: OathViewModel,
    private val dialogManager: DialogManager,
    private val appPreferences: AppPreferences,
) : AppContextManager(), DeviceListener {

    companion object {
        private val memoryKeyProvider = ClearingMemProvider()
    }

    private val dispatcher = Executors.newSingleThreadExecutor().asCoroutineDispatcher()
    private val coroutineScope = CoroutineScope(SupervisorJob() + dispatcher)

    private val oathChannel = MethodChannel(messenger, "android.oath.methods")

    private val keyManager by lazy {
        KeyManager(
            compatUtil.from(Build.VERSION_CODES.M) {
                createKeyStoreProviderM()
            }.otherwise(
                SharedPrefProvider(lifecycleOwner as Context)
            ), memoryKeyProvider
        )
    }

    private val logger = LoggerFactory.getLogger(OathManager::class.java)

    @TargetApi(Build.VERSION_CODES.M)
    private fun createKeyStoreProviderM(): KeyProvider = KeyStoreProvider()

    private val unlockOnConnect = AtomicBoolean(true)
    private var pendingAction: OathAction? = null
    private var refreshJob: Job? = null
    private var addToAny = false
    private val updateDeviceInfo = AtomicBoolean(false)

    override fun onPause() {
        // cancel any pending actions, except for addToAny
        if (!addToAny) {
            pendingAction?.let {
                logger.debug("Cancelling pending action/closing nfc dialog.")
                it.invoke(Result.failure(CancellationException()))
                coroutineScope.launch {
                    dialogManager.closeDialog()
                }
                pendingAction = null
            }
        }
    }

    private val credentialObserver = Observer<List<CredentialWithCode>?> { codes ->
        refreshJob?.cancel()
        if (codes != null && deviceManager.isUsbKeyConnected()) {
            val expirations = codes
                .filter { it.credential.codeType == CodeType.TOTP && !it.credential.touchRequired }
                .mapNotNull { it.code?.validTo }
            if (expirations.isNotEmpty()) {
                val earliest = expirations.min() * 1000
                val now = System.currentTimeMillis()

                refreshJob = coroutineScope.launch {
                    val delayMs = earliest - now
                    logger.debug("Will execute refresh in {}ms", delayMs)
                    if (delayMs > 0) {
                        delay(delayMs)
                    }
                    val currentState = lifecycleOwner.lifecycle.currentState
                    if (currentState.isAtLeast(Lifecycle.State.STARTED)) {
                        requestRefresh()
                    } else {
                        logger.debug(
                            "Cannot run credential refresh in current lifecycle state: {}",
                            currentState
                        )
                    }
                }
            }
        }
    }

    init {
        deviceManager.addDeviceListener(this)
        oathViewModel.credentials.observe(lifecycleOwner, credentialObserver)

        // OATH methods callable from Flutter:
        oathChannel.setHandler(coroutineScope) { method, args ->
            @Suppress("UNCHECKED_CAST")
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

                "addAccountsToAny" -> addAccountsToAny(
                    args["uris"] as List<String>,
                    args["requireTouch"] as List<Boolean>
                )

                else -> throw NotImplementedError()
            }
        }
    }

    override fun dispose() {
        super.dispose()
        deviceManager.removeDeviceListener(this)
        oathViewModel.credentials.removeObserver(credentialObserver)
        oathChannel.setMethodCallHandler(null)
        oathViewModel.clearSession()
        oathViewModel.updateCredentials(mapOf())
        coroutineScope.cancel()
    }

    override suspend fun processYubiKey(device: YubiKeyDevice) {
        try {
            device.withConnection<SmartCardConnection, Unit> { connection ->
                val session = getOathSession(connection)
                val previousId = oathViewModel.currentSession()?.deviceId
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
                            logger.error("Failed to refresh codes", error)
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
                            SmartCardProtocol(connection).select(AppId.OTP)
                        } catch (e: Exception) {
                            logger.error("Failed to recognize this OATH device.", e)
                            // we know this is NFC device and it supports OATH
                            val oathCapabilities = Capabilities(nfc = 0x20)
                            deviceManager.setDeviceInfo(
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
                }
            }
            logger.debug(
                "Successfully read Oath session info (and credentials if unlocked) from connected key"
            )

            if (updateDeviceInfo.getAndSet(false)) {
                deviceManager.setDeviceInfo(getDeviceInfo(device))
            }
        } catch (e: Exception) {
            // OATH not enabled/supported, try to get DeviceInfo over other USB interfaces
            logger.error("Failed to connect to CCID: ", e)

            // Clear any cached OATH state
            oathViewModel.clearSession()
        }
    }

    private suspend fun addAccountToAny(
        uri: String,
        requireTouch: Boolean,
    ): String {
        val credentialData: CredentialData =
            CredentialData.parseUri(URI.create(uri))
        addToAny = true
        return useOathSessionNfc(OathActionDescription.AddAccount) { session ->
            // We need to check for duplicates here since we haven't yet read the credentials
            if (session.credentials.any { it.id.contentEquals(credentialData.id) }) {
                throw IllegalArgumentException()
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

            logger.debug("Added cred {}", credential)
            jsonSerializer.encodeToString(addedCred)
        }
    }

    private suspend fun addAccountsToAny(
        uris: List<String>,
        requireTouch: List<Boolean>,
    ): String {
        logger.trace("Adding following accounts: {}", uris)

        addToAny = true
        return useOathSession(OathActionDescription.AddMultipleAccounts) { session ->
            var successCount = 0
            for (index in uris.indices) {

                val credentialData: CredentialData =
                    CredentialData.parseUri(URI.create(uris[index]))

                if (session.credentials.any { it.id.contentEquals(credentialData.id) }) {
                    logger.info("A credential with this ID already exists, skipping")
                    continue
                }

                val credential = session.putCredential(credentialData, requireTouch[index])
                val code =
                    if (credentialData.oathType == YubiKitOathType.TOTP && !requireTouch[index]) {
                        // recalculate the code
                        calculateCode(session, credential)
                    } else null

                oathViewModel.addCredential(
                    Credential(credential, session.deviceId),
                    Code.from(code)
                )

                logger.trace("Added cred {}", credential)
                successCount++
            }
            jsonSerializer.encodeToString(mapOf("succeeded" to successCount))
        }
    }

    private suspend fun reset(): String =
        useOathSession(OathActionDescription.Reset, updateDeviceInfo = true) {
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
        useOathSession(OathActionDescription.Unlock) {
            val accessKey = it.deriveAccessKey(password.toCharArray())
            keyManager.addKey(it.deviceId, accessKey, remember)

            val unlocked = tryToUnlockOathSession(it)
            val remembered = keyManager.isRemembered(it.deviceId)
            if (unlocked) {
                oathViewModel.setSessionState(Session(it, remembered))

                // fetch credentials after unlocking only if the YubiKey is connected over USB
                if (deviceManager.isUsbKeyConnected()) {
                    oathViewModel.updateCredentials(calculateOathCodes(it))
                }
            }

            jsonSerializer.encodeToString(mapOf("unlocked" to unlocked, "remembered" to remembered))
        }

    private suspend fun setPassword(
        currentPassword: String?,
        newPassword: String,
    ): String =
        useOathSession(
            OathActionDescription.SetPassword,
            unlock = false,
            updateDeviceInfo = true
        ) { session ->
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
            logger.debug("Successfully set password")
            NULL
        }

    private suspend fun unsetPassword(currentPassword: String): String =
        useOathSession(OathActionDescription.UnsetPassword, unlock = false) { session ->
            if (session.isAccessKeySet) {
                // test current password sent by the user
                if (session.unlock(currentPassword.toCharArray())) {
                    session.deleteAccessKey()
                    keyManager.removeKey(session.deviceId)
                    oathViewModel.setSessionState(Session(session, false))
                    logger.debug("Successfully unset password")
                    return@useOathSession NULL
                }
            }
            throw Exception("Unset password failed")
        }

    private fun forgetPassword(): String {
        keyManager.clearAll()
        logger.debug("Cleared all keys.")
        oathViewModel.currentSession()?.let {
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
        useOathSession(OathActionDescription.AddAccount) { session ->
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
        useOathSession(OathActionDescription.RenameAccount) { session ->
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
        useOathSession(OathActionDescription.DeleteAccount) { session ->
            val credential = getOathCredential(session, credentialId)
            session.deleteCredential(credential)
            oathViewModel.removeCredential(Credential(credential, session.deviceId))
            NULL
        }

    private suspend fun requestRefresh() {

        val clearCodes = {
            val currentCredentials = oathViewModel.credentials.value
            oathViewModel.updateCredentials(currentCredentials?.associate {
                it.credential to null
            } ?: emptyMap())
        }

        deviceManager.withKey { usbYubiKeyDevice ->
            try {
                useOathSessionUsb(usbYubiKeyDevice) { session ->
                    try {
                        oathViewModel.updateCredentials(calculateOathCodes(session))
                    } catch (apduException: ApduException) {
                        if (apduException.sw == SW.SECURITY_CONDITION_NOT_SATISFIED) {
                            logger.debug("Handled oath credential refresh on locked session.")
                            oathViewModel.setSessionState(
                                Session(
                                    session,
                                    keyManager.isRemembered(session.deviceId)
                                )
                            )
                        } else {
                            logger.error(
                                "Unexpected sw when refreshing oath credentials",
                                apduException
                            )
                        }
                    }
                }
            } catch (ioException: IOException) {
                logger.error("IOException when accessing USB device: ", ioException)
                clearCodes()
            } catch (illegalStateException: IllegalStateException) {
                logger.error("IllegalStateException when accessing USB device: ", illegalStateException)
                clearCodes()
            }
        }
    }


    private suspend fun calculate(credentialId: String): String =
        useOathSession(OathActionDescription.CalculateCode) { session ->
            val credential = getOathCredential(session, credentialId)

            val code = Code.from(calculateCode(session, credential))
            oathViewModel.updateCode(
                Credential(credential, session.deviceId),
                code
            )
            logger.debug("Code calculated {}", code)

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
    private fun getOathSession(connection: SmartCardConnection): YubiKitOathSession {
        // If OATH is FIPS capable, and we have scpKeyParams, we should use them
        val fips = (deviceManager.deviceInfo?.fipsCapable ?: 0) and Capability.OATH.bit != 0
        val session = YubiKitOathSession(connection, if (fips) deviceManager.scpKeyParams else null)

        if (!unlockOnConnect.compareAndSet(false, true)) {
            tryToUnlockOathSession(session)
        }

        return session
    }


    private fun calculateOathCodes(session: YubiKitOathSession): Map<Credential, Code?> {
        val isUsbKey = deviceManager.isUsbKeyConnected()
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
        oathActionDescription: OathActionDescription,
        unlock: Boolean = true,
        updateDeviceInfo: Boolean = false,
        action: (YubiKitOathSession) -> T
    ): T {

        // callers can decide whether the session should be unlocked first
        unlockOnConnect.set(unlock)
        // callers can request whether device info should be updated after session operation
        this@OathManager.updateDeviceInfo.set(updateDeviceInfo)
        return deviceManager.withKey(
            onUsb = { useOathSessionUsb(it, updateDeviceInfo, action) },
            onNfc = { useOathSessionNfc(oathActionDescription, action) }
        )
    }

    private suspend fun <T> useOathSessionUsb(
        device: UsbYubiKeyDevice,
        updateDeviceInfo: Boolean = false,
        block: (YubiKitOathSession) -> T
    ): T = device.withConnection<SmartCardConnection, T> {
        block(getOathSession(it))
    }.also {
        if (updateDeviceInfo) {
            deviceManager.setDeviceInfo(getDeviceInfo(device))
        }
    }

    private suspend fun <T> useOathSessionNfc(
        oathActionDescription: OathActionDescription,
        block: (YubiKitOathSession) -> T
    ): T {
        try {
            val result = suspendCoroutine { outer ->
                pendingAction = {
                    outer.resumeWith(runCatching {
                        block.invoke(it.value)
                    })
                }
                dialogManager.showDialog(DialogIcon.Nfc, DialogTitle.TapKey, oathActionDescription.id) {
                    logger.debug("Cancelled Dialog {}", oathActionDescription.name)
                    pendingAction?.invoke(Result.failure(CancellationException()))
                    pendingAction = null
                }
            }
            dialogManager.updateDialogState(
                dialogIcon = DialogIcon.Success,
                dialogTitle = DialogTitle.OperationSuccessful
            )
            // TODO: This delays the closing of the dialog, but also the return value
            delay(500)
            return result
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (error: Throwable) {
            dialogManager.updateDialogState(
                dialogIcon = DialogIcon.Failure,
                dialogTitle = DialogTitle.OperationFailed,
                dialogDescriptionId = OathActionDescription.ActionFailure.id
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

    override fun onConnected(device: YubiKeyDevice) {
        refreshJob?.cancel()
    }

    override fun onDisconnected() {
        refreshJob?.cancel()
        oathViewModel.clearSession()
    }

    override fun onTimeout() {
        oathViewModel.clearSession()
    }
}
