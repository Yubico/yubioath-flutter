package com.yubico.authenticator.fido

import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import com.yubico.authenticator.AppContextManager
import com.yubico.authenticator.AppPreferences
import com.yubico.authenticator.DialogIcon
import com.yubico.authenticator.DialogManager
import com.yubico.authenticator.DialogTitle
import com.yubico.authenticator.MainViewModel
import com.yubico.authenticator.asString
import com.yubico.authenticator.device.Info
import com.yubico.authenticator.device.UnknownDevice
import com.yubico.authenticator.fido.data.FidoCredential
import com.yubico.authenticator.fido.data.Session
import com.yubico.authenticator.fido.data.YubiKitFidoSession
import com.yubico.authenticator.setHandler
import com.yubico.authenticator.yubikit.getDeviceInfo
import com.yubico.authenticator.yubikit.withConnection
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.Transport
import com.yubico.yubikit.core.YubiKeyConnection
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.application.ApplicationNotAvailableException
import com.yubico.yubikit.core.fido.CtapException
import com.yubico.yubikit.core.fido.FidoConnection
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.util.Result
import com.yubico.yubikit.fido.ctap.ClientPin
import com.yubico.yubikit.fido.ctap.CredentialManagement
import com.yubico.yubikit.fido.ctap.Ctap2Session.InfoData
import com.yubico.yubikit.fido.ctap.PinUvAuthDummyProtocol
import com.yubico.yubikit.fido.ctap.PinUvAuthProtocol
import com.yubico.yubikit.fido.ctap.PinUvAuthProtocolV1
import com.yubico.yubikit.fido.ctap.PinUvAuthProtocolV2
import com.yubico.yubikit.support.DeviceUtil
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.cancel
import org.json.JSONObject
import org.slf4j.LoggerFactory
import java.util.Arrays
import java.util.concurrent.Executors
import kotlin.coroutines.cancellation.CancellationException
import kotlin.coroutines.suspendCoroutine

typealias FidoAction = (Result<YubiKitFidoSession, Exception>) -> Unit

class FidoManager(
    private val lifecycleOwner: LifecycleOwner,
    messenger: BinaryMessenger,
    private val appViewModel: MainViewModel,
    private val fidoViewModel: FidoViewModel,
    private val dialogManager: DialogManager,
) : AppContextManager {

    companion object {
        const val NFC_DATA_CLEANUP_DELAY = 30L * 1000 // 30s

        fun getPreferredPinUvAuthProtocol(infoData: InfoData): PinUvAuthProtocol {
            val pinUvAuthProtocols = infoData.pinUvAuthProtocols
            val pinSupported = infoData.options["clientPin"] != null
            if (pinSupported) {
                for (protocol in pinUvAuthProtocols) {
                    if (protocol == PinUvAuthProtocolV1.VERSION) {
                        return PinUvAuthProtocolV1()
                    }
                    if (protocol == PinUvAuthProtocolV2.VERSION) {
                        return PinUvAuthProtocolV2()
                    }
                }
            }
            return PinUvAuthDummyProtocol()
        }
    }

    private val dispatcher = Executors.newSingleThreadExecutor().asCoroutineDispatcher()
    private val coroutineScope = CoroutineScope(SupervisorJob() + dispatcher)

    private val fidoChannel = MethodChannel(messenger, "android.fido.methods")

    private val logger = LoggerFactory.getLogger(FidoManager::class.java)
    private var pendingAction: FidoAction? = null
    private var token: ByteArray? = null
    private var clientPin: ClientPin? = null

    private val lifecycleObserver = object : DefaultLifecycleObserver {

        private var startTimeMs: Long = -1

        override fun onPause(owner: LifecycleOwner) {
            startTimeMs = currentTimeMs
            super.onPause(owner)
        }

        override fun onResume(owner: LifecycleOwner) {
            super.onResume(owner)
            if (canInvoke) {
                if (appViewModel.connectedYubiKey.value == null) {
                    // no USB YubiKey is connected, reset known data on resume
                    logger.debug("Removing NFC data after resume.")
                    appViewModel.setDeviceInfo(null)
                    fidoViewModel.setSessionState(null)
                }
            }
        }

        private val currentTimeMs
            get() = System.currentTimeMillis()

        private val canInvoke: Boolean
            get() = startTimeMs != -1L && currentTimeMs - startTimeMs > NFC_DATA_CLEANUP_DELAY
    }

    private val usbObserver = Observer<UsbYubiKeyDevice?> {
        if (it == null) {
            appViewModel.setDeviceInfo(null)
            fidoViewModel.setSessionState(null)
        }
    }

    init {
        appViewModel.connectedYubiKey.observe(lifecycleOwner, usbObserver)
        //fidoViewModel.credentials.observe(lifecycleOwner, credentialObserver)

        // FIDO methods callable from Flutter:
        fidoChannel.setHandler(coroutineScope) { method, args ->
            when (method) {
                "reset" -> noop()

                "unlock" -> unlock(
                    (args["pin"] as String).toCharArray()
                )

                "set_pin" -> setPin(
                    (args["pin"] as String?)?.toCharArray(),
                    (args["new_pin"] as String).toCharArray(),
                )

                "delete_credential" -> deleteCredential(
                    args["rpId"] as String,
                    args["credentialId"] as String
                )

                else -> throw NotImplementedError()
            }
        }

        lifecycleOwner.lifecycle.addObserver(lifecycleObserver)
    }

    override fun dispose() {
        lifecycleOwner.lifecycle.removeObserver(lifecycleObserver)
        appViewModel.connectedYubiKey.removeObserver(usbObserver)
        // oathViewModel.credentials.removeObserver(credentialObserver)
        fidoChannel.setMethodCallHandler(null)
        coroutineScope.cancel()
    }

    private fun noop(): String = ""

    override suspend fun processYubiKey(device: YubiKeyDevice) {

        try {
            if (device.supportsConnection(FidoConnection::class.java)) {
                device.withConnection<FidoConnection, Unit> { connection ->
                    processYubiKey(connection, device)
                }
            } else {
                device.withConnection<SmartCardConnection, Unit> { connection ->
                    processYubiKey(connection, device)
                }
            }
        } catch (e: Exception) {
            // something went wrong, try to get DeviceInfo from any available connection type
            logger.error("Failure when processing YubiKey", e)
            if (device.transport == Transport.USB || e is ApplicationNotAvailableException) {
                val deviceInfo = try {
                    getDeviceInfo(device)
                } catch (e: IllegalArgumentException) {
                    logger.debug("Device was not recognized")
                    UnknownDevice.copy(isNfc = device.transport == Transport.NFC)
                } catch (e: Exception) {
                    logger.error("Failure getting device info", e)
                    null
                }

                logger.debug("Setting device info: {}", deviceInfo)
                appViewModel.setDeviceInfo(deviceInfo)
            }

            // Clear any cached FIDO state
            fidoViewModel.setSessionState(null)
        }

    }

    private fun processYubiKey(connection: YubiKeyConnection, device: YubiKeyDevice) {
        val fidoSession =
            if (connection is FidoConnection) {
                YubiKitFidoSession(connection)
            } else {
                YubiKitFidoSession(connection as SmartCardConnection)
            }

        val previousAaguid = fidoViewModel.sessionState.value?.info?.aaguid?.asString()
        val sessionAaguid = fidoSession.cachedInfo.aaguid.asString()

        logger.debug(
            "Previous aaguid: {}, current aaguid: {}",
            previousAaguid,
            sessionAaguid
        )

        if (sessionAaguid == previousAaguid && device is NfcYubiKeyDevice) {
            // Run any pending action
            pendingAction?.let { action ->
                action.invoke(Result.success(fidoSession))
                pendingAction = null
            }

            // not possible to reuse token in new session
            //    token?.let {
            //        // read creds
            //
            //        val credentials = getCredentials(fidoSession, clientPin!!, it)
            //        logger.debug("Creds: {}", credentials)
            //        fidoViewModel.updateCredentials(credentials)
            //    }
        } else {

            if (sessionAaguid != previousAaguid) {
                // different key
                logger.debug("This is a different key than previous, invalidating the PIN token")
                if (token != null) {
                    Arrays.fill(token!!, 0.toByte())
                    token = null
                    clientPin = null
                }
            }

            fidoViewModel.setSessionState(
                Session(
                    fidoSession,
                    token != null
                )
            )

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

    private fun unlockSession(
        fidoSession: YubiKitFidoSession,
        pin: CharArray
    ): String {
        val permissions =
            if (CredentialManagement.isSupported(fidoSession.cachedInfo))
                ClientPin.PIN_PERMISSION_CM
            else
                0
        // TODO: Add bio Enrollment permissions if supported

        clientPin =
            ClientPin(fidoSession, getPreferredPinUvAuthProtocol(fidoSession.cachedInfo))
        if (permissions != 0) {
            token = clientPin!!.getPinToken(pin, permissions, "")

            val credentials = getCredentials(fidoSession, clientPin!!, token!!)
            logger.debug("Creds: {}", credentials)
            fidoViewModel.updateCredentials(credentials)

        } else {
            clientPin!!.getPinToken(pin, permissions, "yubico-authenticator.example.com")
        }

        fidoViewModel.setSessionState(
            Session(
                fidoSession,
                token != null
            )
        )
        return JSONObject(mapOf("success" to true)).toString()
    }

    private fun catchPinErrors(block: () -> String): String =
        try {
            block()
        } catch (ctapException: CtapException) {
            if (ctapException.ctapError == CtapException.ERR_PIN_INVALID ||
                ctapException.ctapError == CtapException.ERR_PIN_BLOCKED ||
                ctapException.ctapError == CtapException.ERR_PIN_AUTH_BLOCKED
            ) {
                token = null
                fidoViewModel.updateCredentials(emptyList())
                val pinRetriesResult = clientPin!!.pinRetries
                JSONObject(
                    mapOf(
                        "success" to false,
                        "pinRetries" to pinRetriesResult.count,
                        "authBlocked" to (ctapException.ctapError == CtapException.ERR_PIN_AUTH_BLOCKED)
                    )
                ).toString()
            } else {
                throw ctapException
            }
        }

    private suspend fun unlock(pin: CharArray): String =
        useSession(FidoActionDescription.Unlock) { fidoSession ->

            try {
                catchPinErrors {
                    unlockSession(fidoSession, pin)
                }

            } finally {
                Arrays.fill(pin, 0.toChar())
            }
        }

    private fun setOrChangePin(
        fidoSession: YubiKitFidoSession,
        pin: CharArray?,
        newPin: CharArray
    ) {
        val infoData = fidoSession.cachedInfo
        val hasPin = infoData.options["clientPin"] == true

        if (hasPin) {
            clientPin!!.changePin(pin!!, newPin)
        } else {
            clientPin!!.setPin(newPin)
        }
    }

    private suspend fun setPin(pin: CharArray?, newPin: CharArray): String =
        useSession(FidoActionDescription.SetPin) { fidoSession ->
            try {
                catchPinErrors {
                    setOrChangePin(fidoSession, pin, newPin)
                    unlockSession(fidoSession, newPin)
                }
            } finally {
                Arrays.fill(newPin, 0.toChar())
                pin?.let {
                    Arrays.fill(it, 0.toChar())
                }
            }
        }

    private fun getCredentials(
        fidoSession: YubiKitFidoSession,
        clientPin: ClientPin,
        pinUvAuthToken: ByteArray
    ): List<FidoCredential> =
        try {
            val credMan = CredentialManagement(fidoSession, clientPin.pinUvAuth, pinUvAuthToken)
            val rpIds = credMan.enumerateRps()

            val credentials = rpIds.map { rpData ->
                credMan.enumerateCredentials(rpData.rpIdHash).map { credential ->
                    FidoCredential(
                        rpData.rp["id"] as String,
                        (credential.credentialId["id"] as ByteArray).asString(),
                        (credential.user["id"] as ByteArray).asString(),
                        credential.user["name"] as String
                    )
                }
            }.reduceOrNull { credentials, credentialList ->
                credentials + credentialList
            }

            credentials ?: emptyList()
        } finally {

        }

    private suspend fun deleteCredential(rpId: String, credentialId: String): String =
        useSession(FidoActionDescription.SetPin) { _ ->
            ""
        }

    private suspend fun <T> useSession(
        actionDescription: FidoActionDescription,
        action: (YubiKitFidoSession) -> T
    ): T {
        return appViewModel.connectedYubiKey.value?.let {
            useSessionUsb(it, action)
        } ?: useSessionNfc(actionDescription, action)
    }

    private suspend fun <T> useSessionUsb(
        device: UsbYubiKeyDevice,
        block: (YubiKitFidoSession) -> T
    ): T = device.withConnection<FidoConnection, T> {
        block(YubiKitFidoSession(it))
    }

    private suspend fun <T> useSessionNfc(
        actionDescription: FidoActionDescription,
        block: (YubiKitFidoSession) -> T
    ): T {
        try {
            val result = suspendCoroutine { outer ->
                pendingAction = {
                    outer.resumeWith(runCatching {
                        block.invoke(it.value)
                    })
                }
                dialogManager.showDialog(
                    DialogIcon.Nfc,
                    DialogTitle.TapKey,
                    actionDescription.id
                ) {
                    logger.debug("Cancelled Dialog {}", actionDescription.name)
                    pendingAction?.invoke(Result.failure(CancellationException()))
                    pendingAction = null
                }
            }
            // Personally I find it better to not have the dialog updates for FIDO
            //    dialogManager.updateDialogState(
            //        dialogIcon = DialogIcon.Success,
            //        dialogTitle = DialogTitle.OperationSuccessful
            //    )
            //    // TODO: This delays the closing of the dialog, but also the return value
            //    delay(500)
            return result
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (error: Throwable) {
            // Personally I find it better to not have the dialog updates for FIDO
            //    dialogManager.updateDialogState(
            //        dialogIcon = DialogIcon.Failure,
            //        dialogTitle = DialogTitle.OperationFailed,
            //        dialogDescriptionId = FidoActionDescription.ActionFailure.id
            //    )
            //    // TODO: This delays the closing of the dialog, but also the return value
            //    delay(1500)
            throw error
        } finally {
            dialogManager.closeDialog()
        }
    }
}