package com.yubico.authenticator.data

import com.yubico.authenticator.AppPreferences
import com.yubico.authenticator.asString
import com.yubico.authenticator.jsonSerializer
import com.yubico.authenticator.logging.Log
import com.yubico.authenticator.oath.KeyManager
//import com.yubico.authenticator.oath.OathManager
import com.yubico.authenticator.oath.data.Code
import com.yubico.authenticator.oath.data.Credential
import com.yubico.authenticator.oath.data.CredentialWithCode
import com.yubico.authenticator.oath.data.Session
import com.yubico.authenticator.oath.data.YubiKitOathSession
import com.yubico.authenticator.oath.data.calculateSteamCode
import com.yubico.authenticator.oath.data.isSteamCredential
import com.yubico.authenticator.oath.keystore.ClearingMemProvider
import com.yubico.authenticator.yubikit.withConnection
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.Transport
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.oath.OathSession
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.serialization.encodeToString
import java.util.concurrent.ArrayBlockingQueue

interface OathModel {
    fun getSession(): Flow<Session?>
    fun getCredentials(): Flow<List<CredentialWithCode>?>

    suspend fun <T> useOathSession(
        title: String,
        action: (YubiKitOathSession) -> T
    ): T

    suspend fun renameAccount(uri: String, name: String, issuer: String?): String
}

class YubiKitOathModel (
    private val keyManager: KeyManager,
    private val memoryKeyProvider: ClearingMemProvider,
    private val appPreferences: AppPreferences,
    private val deviceModel: DeviceModel
) : OathModel, ConnectionListener {

    private var currentCredentials : List<CredentialWithCode> = ArrayList()

    private val sessionQueue = ArrayBlockingQueue<Result<Session?>>(1)
    private val credentialsQueue = ArrayBlockingQueue<Result<List<CredentialWithCode>?>>(1)

    private var currentSession : Session? = null

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
                        currentCredentials = calculateOathCodes(session).map {
                            CredentialWithCode(it.key, it.value)
                        }
                        credentialsQueue.add(Result.success(currentCredentials))
//              oathViewModel.updateCredentials(calculateOathCodes(session))
                    }
                } catch (error: Exception) {
                    //Log.e(OathManager.TAG, "Failed to refresh codes", error.toString())
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
                currentCredentials = calculateOathCodes(session).map {
                    CredentialWithCode(it.key, it.value)
                }
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
        Log.d(TAG,"OathModel says goodbye")
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

    private fun calculateOathCodes(session: YubiKitOathSession): Map<Credential, Code?> {
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

    override suspend fun <T> useOathSession(
        title: String,
        action: (YubiKitOathSession) -> T
    ): T {
        return deviceModel.useDevice(title) {
            it.withConnection<SmartCardConnection, T> { smartCardConnection ->
                val oathSession = OathSession(smartCardConnection)
                action(oathSession)
            }
        }
    }

    override suspend fun renameAccount(uri: String, name: String, issuer: String?): String =
        useOathSession("Rename") { session ->
            val credential = getOathCredential(session, uri)
            val renamedCredential =
                Credential(session.renameCredential(credential, name, issuer), session.deviceId)
//            oathViewModel.renameCredential(
//                Credential(credential, session.deviceId),
//                renamedCredential
//            )

            val oldCredential =  Credential(credential, session.deviceId)

            val entry = currentCredentials.find { it.credential == oldCredential }!!
            require(entry.credential.deviceId == renamedCredential.deviceId) {
                "Cannot rename credential for different deviceId"
            }
            credentialsQueue.add(Result.success(currentCredentials.minus(entry).plus(
                CredentialWithCode(renamedCredential, entry.code))))

            jsonSerializer.encodeToString(renamedCredential)
        }

    private fun getOathCredential(session: YubiKitOathSession, credentialId: String) =
        // we need to use oathSession.calculateCodes() to get proper Credential.touchRequired value
        session.calculateCodes().map { e -> e.key }.firstOrNull { credential ->
            (credential != null) && credential.id.asString() == credentialId
        } ?: throw Exception("Failed to find account")


    suspend fun <T> useOathSessionUsb(
        device: UsbYubiKeyDevice,
        block: (YubiKitOathSession) -> T
    ): T = device.withConnection<SmartCardConnection, T> {
        val session = YubiKitOathSession(it)
        tryToUnlockOathSession(session)
        block(session)
    }

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


}