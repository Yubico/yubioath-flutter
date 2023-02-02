package com.yubico.authenticator.data

import com.yubico.authenticator.AppPreferences
import com.yubico.authenticator.NULL
import com.yubico.authenticator.asString
import com.yubico.authenticator.jsonSerializer
import com.yubico.authenticator.logging.Log
import com.yubico.authenticator.oath.KeyManager
import com.yubico.authenticator.oath.data.Code
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
import com.yubico.authenticator.yubikit.withConnection
import com.yubico.yubikit.core.Transport
import com.yubico.yubikit.core.smartcard.ApduException
import com.yubico.yubikit.core.smartcard.SW
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.oath.CredentialData
import com.yubico.yubikit.oath.OathSession
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.serialization.encodeToString
import java.net.URI
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.CancellationException

interface OathModel {
    fun getSession(): Flow<Session?>
    fun getCredentials(): Flow<List<CredentialWithCode>?>

    suspend fun <T> useOathSession(
        title: String,
        action: (YubiKitOathSession) -> T
    ): T

    suspend fun reset(): String

    suspend fun unlock(password: String, remember: Boolean): String

    suspend fun setPassword(currentPassword: String?, newPassword: String): String

    suspend fun unsetPassword(currentPassword: String): String

    suspend fun forgetPassword(): String

    suspend fun calculate(credentialId: String): String

    suspend fun addAccount(uri: String, requireTouch: Boolean): String

    suspend fun renameAccount(uri: String, name: String, issuer: String?): String

    suspend fun deleteAccount(credentialId: String): String

    suspend fun addAccountToAny(uri: String, requireTouch: Boolean): String
}

class YubiKitOathModel(
    private val keyManager: KeyManager,
    private val memoryKeyProvider: ClearingMemProvider,
    private val appPreferences: AppPreferences,
    private val deviceModel: DeviceModel
) : OathModel, ConnectionListener {

    private var currentCredentials: List<CredentialWithCode> = ArrayList()

    private val sessionQueue = ArrayBlockingQueue<Result<Session?>>(1)
    private val credentialsQueue = ArrayBlockingQueue<Result<List<CredentialWithCode>?>>(1)

    private var currentSession: Session? = null

    init {
        deviceModel.addConnectionListener(this)
    }

    override fun getSession(): Flow<Session?> = flow {
        while (true) {
            currentSession = sessionQueue.take().getOrNull()
            Log.d(TAG, "Emitting new session state")
            emit(currentSession)
        }
    }.flowOn(Dispatchers.IO)

    override fun getCredentials(): Flow<List<CredentialWithCode>?> = flow {
        while (true) {
            val result = credentialsQueue.take()
            Log.d(TAG, "Emitting new credentials")
            emit(result.getOrNull())
        }
    }.flowOn(Dispatchers.IO)


    override fun onSmartCardConnection(connection: SmartCardConnection) {
        Log.d(TAG, "OathModel is happy")


        val session = YubiKitOathSession(connection)
        tryToUnlockOathSession(session)

        val previousId = currentSession?.deviceId
        if (session.deviceId == previousId) {
            // Run any pending action
//            pendingAction?.let { action ->
//                action.invoke(com.yubico.yubikit.core.util.Result.success(session))
//                pendingAction = null
//            }

            // Refresh codes
            if (!session.isLocked) {
                try {
                    if (!session.isLocked) {
                        currentCredentials = calculateOathCodes(session)
                        credentialsQueue.add(Result.success(currentCredentials))
//              oathViewModel.updateCredentials(calculateOathCodes(session))
                    }
                } catch (error: Exception) {
                    //Log.e(TAG, "Failed to refresh codes", error.toString())
                }
            }
        } else {
            // Clear in-memory password for any previous device
            if (connection.transport == Transport.NFC && previousId != null) {
                memoryKeyProvider.removeKey(previousId)
            }


            // Update the OATH state
            sessionQueue.add(
                Result.success(
                    Session(
                        session,
                        keyManager.isRemembered(session.deviceId)
                    )
                )
            )

//            oathViewModel.setSessionState(
//                Session(
//                    session,
//                    keyManager.isRemembered(session.deviceId)
//                )
//            )
            if (!session.isLocked) {
                currentCredentials = calculateOathCodes(session)
                credentialsQueue.add(Result.success(currentCredentials))
//              oathViewModel.updateCredentials(calculateOathCodes(session))
            }

//            // Awaiting an action for a different or no device?
//            pendingAction?.let { action ->
//                pendingAction = null
//                if (addToAny) {
//                    // Special "add to any YubiKey" action, process
//                    addToAny = false
//                    action.invoke(com.yubico.yubikit.core.util.Result.success(session))
//                } else {
//                    // Awaiting an action for a different device? Fail it and stop processing.
//                    action.invoke(com.yubico.yubikit.core.util.Result.failure(IllegalStateException("Wrong deviceId")))
//                    return@withConnection
//                }
//            }
//
//            if (session.version.isLessThan(4, 0, 0) && connection.transport == Transport.NFC) {
//                // NEO over NFC, select OTP applet before reading info
//                SmartCardProtocol(connection).select(OathManager.OTP_AID)
//            }

            // HANDLED by deviceModel
//            // Update deviceInfo since the deviceId has changed
//            val pid = (device as? UsbYubiKeyDevice)?.pid
//            val deviceInfo = DeviceUtil.readInfo(connection, pid)
//            appViewModel.setDeviceInfo(
//                Info(
//                    name = DeviceUtil.getName(deviceInfo, pid?.type),
//                    isNfc = device.transport == Transport.NFC,
//                    usbPid = pid?.value,
//                    deviceInfo = deviceInfo
//                )
//            )
        }
    }


    override fun onDisconnect() {
        Log.d(TAG, "OathModel says goodbye")
    }


    companion object {
        private const val TAG = "YubiKitOathModel"
    }


    // from oathmanager
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

    private fun calculateOathCodes(session: YubiKitOathSession): List<CredentialWithCode> {
        val isUsbKey = true // appViewModel.connectedYubiKey.value != null
        var timestamp = System.currentTimeMillis()
        if (!isUsbKey) {
            // NFC, need to pad timer to avoid immediate expiration
            timestamp += 10000
        }
        val bypassTouch = appPreferences.bypassTouchOnNfcTap && !isUsbKey
        return session.calculateCodes(timestamp).map { (credential, code) ->
            Pair(
                Credential(credential, session.deviceId),
                Code.from(
                    if (credential.isSteamCredential() && (!credential.isTouchRequired || bypassTouch)) {
                        session.calculateSteamCode(credential, timestamp)
                    } else if (credential.isTouchRequired && bypassTouch) {
                        session.calculateCode(credential, timestamp)
                    } else {
                        code
                    }
                )
            )
        }.toMap().map {
            CredentialWithCode(it.key, it.value)
        }
    }

    override suspend fun <T> useOathSession(
        title: String,
        action: (YubiKitOathSession) -> T
    ): T {
        return deviceModel.useDevice(title) {
            it.withConnection<SmartCardConnection, T> { smartCardConnection ->
                val oathSession = OathSession(smartCardConnection)
                if (deviceModel.isUsbDeviceConnected()) {
                    tryToUnlockOathSession(oathSession)
                }
                action(oathSession)
            }
        }
    }

    override suspend fun reset(): String =
        useOathSession("Reset YubiKey") {
            // note, it is ok to reset locked session
            it.reset()
            keyManager.removeKey(it.deviceId)
            currentSession = Session(it, false)
            sessionQueue.add(Result.success(currentSession))
            NULL
        }

    override suspend fun unlock(password: String, remember: Boolean): String =
        useOathSession("Unlocking") {
            val accessKey = it.deriveAccessKey(password.toCharArray())
            keyManager.addKey(it.deviceId, accessKey, remember)

            val unlocked = tryToUnlockOathSession(it)
            val remembered = keyManager.isRemembered(it.deviceId)
            if (unlocked) {
                currentSession = Session(it, remembered)
                currentCredentials = calculateOathCodes(it)
                sessionQueue.add(Result.success(currentSession))
                credentialsQueue.add(Result.success(currentCredentials))
            }

            jsonSerializer.encodeToString(mapOf("unlocked" to unlocked, "remembered" to remembered))
        }

    override suspend fun setPassword(currentPassword: String?, newPassword: String): String =
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
            keyManager.addKey(session.deviceId, accessKey, false)
            currentSession = Session(session, false)
            sessionQueue.add(Result.success(currentSession))
            Log.d(TAG, "Successfully set password")
            NULL
        }

    override suspend fun unsetPassword(currentPassword: String): String =
        useOathSession("Unset password") { session ->
            if (session.isAccessKeySet) {
                // test current password sent by the user
                if (session.unlock(currentPassword.toCharArray())) {
                    session.deleteAccessKey()
                    keyManager.removeKey(session.deviceId)
                    currentSession = Session(session, false)
                    sessionQueue.add(Result.success(currentSession))
                    Log.d(TAG, "Successfully unset password")
                    return@useOathSession NULL
                }
            }
            throw Exception("Unset password failed")
        }

    override suspend fun forgetPassword(): String {
        keyManager.clearAll()
        Log.d(TAG, "Cleared all keys.")
        currentSession?.let {
            currentSession = it.copy(
                isLocked = it.isAccessKeySet,
                isRemembered = false
            )
            sessionQueue.add(Result.success(currentSession))
        }
        return NULL
    }


    override suspend fun calculate(credentialId: String): String = TODO("Implement")

    override suspend fun addAccount(uri: String, requireTouch: Boolean): String =
        useOathSession("Add account") { session ->
// TODO: implement this
//            require(credential.deviceId == currentSession?.deviceId) {
//                "Cannot add credential for different deviceId"
//            }

            val credentialData: CredentialData =
                CredentialData.parseUri(URI.create(uri))

            val credential = session.putCredential(credentialData, requireTouch)

            val code =
                if (credentialData.oathType == YubiKitOathType.TOTP && !requireTouch) {
                    // recalculate the code
                    calculateCode(session, credential)
                } else null


            val addedCred = CredentialWithCode(
                Credential(credential, session.deviceId),
                Code.from(code)
            )

            currentCredentials = currentCredentials.plus(addedCred)
            credentialsQueue.add(Result.success(currentCredentials))

            jsonSerializer.encodeToString(addedCred)
        }

    override suspend fun renameAccount(uri: String, name: String, issuer: String?): String =
        useOathSession("Rename") { session ->
            val credential = getOathCredential(session, uri)
            val renamedCredential =
                Credential(session.renameCredential(credential, name, issuer), session.deviceId)

            val oldCredential = Credential(credential, session.deviceId)

            val entry = currentCredentials.find { it.credential == oldCredential }!!
            require(entry.credential.deviceId == renamedCredential.deviceId) {
                "Cannot rename credential for different deviceId"
            }
            currentCredentials = currentCredentials.minus(entry).plus(
                CredentialWithCode(renamedCredential, entry.code)
            )
            credentialsQueue.add(Result.success(currentCredentials))

            jsonSerializer.encodeToString(renamedCredential)
        }

    override suspend fun deleteAccount(credentialId: String): String =
        useOathSession("Delete account") { session ->
            val credential = getOathCredential(session, credentialId)
            session.deleteCredential(credential)

            val entry = currentCredentials.find {
                it.credential == Credential(
                    credential,
                    session.deviceId
                )
            }!!
            currentCredentials = currentCredentials.minus(entry)
            credentialsQueue.add(Result.success(currentCredentials))
            NULL
        }

    override suspend fun addAccountToAny(uri: String, requireTouch: Boolean): String =
        TODO("Implement")


    private fun getOathCredential(session: YubiKitOathSession, credentialId: String) =
        // we need to use oathSession.calculateCodes() to get proper Credential.touchRequired value
        session.calculateCodes().map { e -> e.key }.firstOrNull { credential ->
            (credential != null) && credential.id.asString() == credentialId
        } ?: throw Exception("Failed to find account")


//    suspend fun <T> useOathSessionUsb(
//        device: UsbYubiKeyDevice,
//        block: (YubiKitOathSession) -> T
//    ): T = device.withConnection<SmartCardConnection, T> {
//        val session = YubiKitOathSession(it)
//        tryToUnlockOathSession(session)
//        block(session)
//    }

//    private suspend fun <T> useOathSessionNfc(
//        title: String,
//        block: (YubiKitOathSession) -> T
//    ): T {
    //       try {
//            val result = suspendCoroutine<T> { outer ->
////                pendingAction = {
////                    outer.resumeWith(runCatching {
////                        block.invoke(it.value)
////                    })
////                }
//                dialogManager.showDialog(Icon.NFC, "Tap your key", title) {
//                    Log.d(TAG, "Cancelled Dialog $title")
////                    pendingAction?.invoke(Result.failure(CancellationException()))
////                    pendingAction = null
//                }
//            }
//            dialogManager.updateDialogState(
//                icon = Icon.SUCCESS,
//                title = "Success"
//            )
//            // TODO: This delays the closing of the dialog, but also the return value
//            delay(500)
//            return result
//        } catch (cancelled: CancellationException) {
//            throw cancelled
//        } catch (error: Throwable) {
//            dialogManager.updateDialogState(
//                icon = Icon.ERROR,
//                title = "Failure",
//                description = "Action failed - try again"
//            )
//            // TODO: This delays the closing of the dialog, but also the return value
//            delay(1500)
//            throw error
//        } finally {
//            dialogManager.closeDialog()
//        }
//    }


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

}