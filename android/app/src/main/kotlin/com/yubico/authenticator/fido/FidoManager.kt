/*
 * Copyright (C) 2024 Yubico.
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

package com.yubico.authenticator.fido

import com.yubico.authenticator.AppContextManager
import com.yubico.authenticator.DialogManager
import com.yubico.authenticator.MainViewModel
import com.yubico.authenticator.NULL
import com.yubico.authenticator.asString
import com.yubico.authenticator.device.DeviceListener
import com.yubico.authenticator.device.DeviceManager
import com.yubico.authenticator.device.Info
import com.yubico.authenticator.device.UnknownDevice
import com.yubico.authenticator.fido.data.FidoCredential
import com.yubico.authenticator.fido.data.FidoFingerprint
import com.yubico.authenticator.fido.data.Session
import com.yubico.authenticator.fido.data.SessionInfo
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
import com.yubico.yubikit.core.application.CommandState
import com.yubico.yubikit.core.fido.CtapException
import com.yubico.yubikit.core.fido.FidoConnection
import com.yubico.yubikit.core.internal.Logger
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.util.Result
import com.yubico.yubikit.fido.ctap.BioEnrollment
import com.yubico.yubikit.fido.ctap.ClientPin
import com.yubico.yubikit.fido.ctap.CredentialManagement
import com.yubico.yubikit.fido.ctap.Ctap2Session.InfoData
import com.yubico.yubikit.fido.ctap.FingerprintBioEnrollment
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
import java.io.IOException
import java.util.Arrays
import java.util.concurrent.Executors

typealias FidoAction = (Result<YubiKitFidoSession, Exception>) -> Unit

class FidoManager(
    messenger: BinaryMessenger,
    private val deviceManager: DeviceManager,
    private val fidoViewModel: FidoViewModel,
    mainViewModel: MainViewModel,
    dialogManager: DialogManager,
) : AppContextManager(), DeviceListener {

    @OptIn(ExperimentalStdlibApi::class)
    private object HexCodec {
        fun bytesToHexString(bytes: ByteArray) : String = bytes.toHexString()
        fun hexStringToBytes(hex: String) : ByteArray = hex.hexToByteArray()
    }

    companion object {
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

    private val connectionHelper = FidoConnectionHelper(deviceManager, dialogManager)

    private val dispatcher = Executors.newSingleThreadExecutor().asCoroutineDispatcher()
    private val coroutineScope = CoroutineScope(SupervisorJob() + dispatcher)

    private val fidoChannel = MethodChannel(messenger, "android.fido.methods")

    private val logger = LoggerFactory.getLogger(FidoManager::class.java)

    private val pinStore = FidoPinStore()

    private var pinRetries : Int? = null

    private val resetHelper =
        FidoResetHelper(deviceManager, fidoViewModel, mainViewModel, connectionHelper, pinStore)

    override fun onPause() {
        resetHelper.onPause()
    }

    override fun onResume() {
        resetHelper.onResume()
    }

    init {
        pinRetries = null

        deviceManager.addDeviceListener(this)

        fidoChannel.setHandler(coroutineScope) { method, args ->
            when (method) {
                "reset" -> resetHelper.reset()

                "cancelReset" -> resetHelper.cancelReset()

                "unlock" -> unlock(
                    (args["pin"] as String).toCharArray()
                )

                "setPin" -> setPin(
                    (args["pin"] as String?)?.toCharArray(),
                    (args["newPin"] as String).toCharArray(),
                )

                "deleteCredential" -> deleteCredential(
                    args["rpId"] as String,
                    args["credentialId"] as String
                )

                "deleteFingerprint" -> deleteFingerprint(
                    args["templateId"] as String
                )

                "renameFingerprint" -> renameFingerprint(
                    args["templateId"] as String,
                    args["name"] as String
                )

                "registerFingerprint" -> registerFingerprint(
                    args["name"] as String?,
                )

                "cancelRegisterFingerprint" -> cancelRegisterFingerprint()

                else -> throw NotImplementedError()
            }
        }
    }

    override fun dispose() {
        super.dispose()
        deviceManager.removeDeviceListener(this)
        fidoChannel.setMethodCallHandler(null)
        fidoViewModel.clearSessionState()
        fidoViewModel.updateCredentials(emptyList())
        coroutineScope.cancel()
    }

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
            logger.error("Failure when processing YubiKey: ", e)

            // Clear any cached FIDO state
            fidoViewModel.clearSessionState()
        }

    }

    private fun processYubiKey(connection: YubiKeyConnection, device: YubiKeyDevice) {
        val fidoSession =
            if (connection is FidoConnection) {
                YubiKitFidoSession(connection)
            } else {
                YubiKitFidoSession(connection as SmartCardConnection)
            }

        val previousSession = fidoViewModel.currentSession()?.info
        val currentSession = SessionInfo(fidoSession.cachedInfo)
        logger.debug(
            "Previous session: {}, current session: {}",
            previousSession,
            currentSession
        )

        val sameDevice = currentSession.equals(previousSession)

        if (device is NfcYubiKeyDevice && (sameDevice || resetHelper.inProgress)) {
            connectionHelper.invokePending(fidoSession)
        } else {

            if (!sameDevice) {
                // different key
                logger.debug("This is a different key than previous, invalidating the PIN token")
                pinStore.setPin(null)
                connectionHelper.cancelPending()
            }

            val infoData = fidoSession.cachedInfo
            val clientPin =
                ClientPin(fidoSession, getPreferredPinUvAuthProtocol(infoData))

            pinRetries = if (infoData.options["clientPin"] == true) clientPin.pinRetries.count else null

            fidoViewModel.setSessionState(
                Session(infoData, pinStore.hasPin(), pinRetries)
            )
        }
    }

    private fun getPinPermissionsCM(fidoSession: YubiKitFidoSession): Int {
        return if (CredentialManagement.isSupported(fidoSession.cachedInfo))
            ClientPin.PIN_PERMISSION_CM else 0
    }

    private fun getPinPermissionsBE(fidoSession: YubiKitFidoSession): Int {
        return if (BioEnrollment.isSupported(fidoSession.cachedInfo))
            ClientPin.PIN_PERMISSION_BE else 0
    }

    private fun unlockSession(
        fidoSession: YubiKitFidoSession,
        clientPin: ClientPin,
        pin: CharArray
    ): String {

        val pinPermissionsCM = getPinPermissionsCM(fidoSession)
        val pinPermissionsBE = getPinPermissionsBE(fidoSession)
        val permissions = pinPermissionsCM or pinPermissionsBE

        if (permissions != 0) {
            val token = clientPin.getPinToken(pin, permissions, null)
            val credentials = getCredentials(fidoSession, clientPin, token)
            logger.debug("Creds: {}", credentials)
            fidoViewModel.updateCredentials(credentials)

            if (pinPermissionsBE != 0) {
                val fingerprints = getFingerprints(fidoSession, clientPin, token)
                logger.debug("Fingerprints: {}", fingerprints)
                fidoViewModel.updateFingerprints(fingerprints)
            }
        } else {
            clientPin.getPinToken(pin, permissions, "yubico-authenticator.example.com")
        }

        pinStore.setPin(pin)

        pinRetries = clientPin.pinRetries.count

        fidoViewModel.setSessionState(
            Session(
                fidoSession.info,
                pinStore.hasPin(),
                pinRetries
            )
        )
        return JSONObject(mapOf("success" to true)).toString()
    }

    private fun catchPinErrors(
        fidoSession: YubiKitFidoSession,
        clientPin: ClientPin,
        block: () -> String
    ): String =
        try {
            block()
        } catch (ctapException: CtapException) {
            if (ctapException.ctapError == CtapException.ERR_PIN_INVALID ||
                ctapException.ctapError == CtapException.ERR_PIN_BLOCKED ||
                ctapException.ctapError == CtapException.ERR_PIN_AUTH_BLOCKED ||
                ctapException.ctapError == CtapException.ERR_PIN_POLICY_VIOLATION
            ) {
                pinStore.setPin(null)
                fidoViewModel.updateCredentials(emptyList())
                pinRetries = clientPin.pinRetries.count

                fidoViewModel.setSessionState(
                    Session(
                        fidoSession.info,
                        pinStore.hasPin(),
                        pinRetries
                    )
                )

                if (ctapException.ctapError == CtapException.ERR_PIN_POLICY_VIOLATION) {
                    JSONObject(
                        mapOf(
                            "success" to false,
                            "pinViolation" to true
                        )
                    ).toString()
                } else {
                    JSONObject(
                        mapOf(
                            "success" to false,
                            "pinRetries" to pinRetries,
                            "authBlocked" to (ctapException.ctapError == CtapException.ERR_PIN_AUTH_BLOCKED),
                        )
                    ).toString()
                }
            } else {
                throw ctapException
            }
        }

    private suspend fun unlock(pin: CharArray): String =
        connectionHelper.useSession(FidoActionDescription.Unlock) { fidoSession ->

            try {
                val clientPin =
                    ClientPin(fidoSession, getPreferredPinUvAuthProtocol(fidoSession.cachedInfo))

                catchPinErrors(fidoSession, clientPin) {
                    unlockSession(fidoSession, clientPin, pin)
                }
            } catch (e: IOException) {
                // something failed, keep the session locked
                fidoViewModel.currentSession()?.let {
                    fidoViewModel.setSessionState(it.copy(info = it.info, unlocked = false))
                }
                throw e
            } finally {
                Arrays.fill(pin, 0.toChar())
            }
        }

    private fun setOrChangePin(
        fidoSession: YubiKitFidoSession,
        clientPin: ClientPin,
        pin: CharArray?,
        newPin: CharArray
    ) {
        val infoData = fidoSession.cachedInfo
        val hasPin = infoData.options["clientPin"] == true

        if (hasPin) {
            clientPin.changePin(pin!!, newPin)
        } else {
            clientPin.setPin(newPin)
        }
    }

    private suspend fun setPin(pin: CharArray?, newPin: CharArray): String =
        connectionHelper.useSession(FidoActionDescription.SetPin) { fidoSession ->
            try {
                val clientPin =
                    ClientPin(fidoSession, getPreferredPinUvAuthProtocol(fidoSession.cachedInfo))

                catchPinErrors(fidoSession, clientPin) {
                    setOrChangePin(fidoSession, clientPin, pin, newPin)
                    unlockSession(fidoSession, clientPin, newPin)
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
                credMan.enumerateCredentials(rpData.rpIdHash).map { credentialData ->
                    FidoCredential(
                        rpData.rp["id"] as String,
                        (credentialData.credentialId["id"] as ByteArray).asString(),
                        (credentialData.user["id"] as ByteArray).asString(),
                        credentialData.user["name"] as String,
                        publicKeyCredentialDescriptor = credentialData.credentialId,
                        displayName = credentialData.user["displayName"] as String?,
                    )
                }
            }.reduceOrNull { credentials, credentialList ->
                credentials + credentialList
            }

            credentials ?: emptyList()
        } finally {

        }

    private suspend fun deleteCredential(rpId: String, credentialId: String): String =
        connectionHelper.useSession(FidoActionDescription.DeleteCredential) { fidoSession ->

            val clientPin =
                ClientPin(fidoSession, getPreferredPinUvAuthProtocol(fidoSession.cachedInfo))

            val permissions = getPinPermissionsCM(fidoSession)
            val token = clientPin.getPinToken(pinStore.getPin(), permissions, null)
            val credMan = CredentialManagement(fidoSession, clientPin.pinUvAuth, token)

            val credentialDescriptor =
                fidoViewModel.credentials.value?.firstOrNull {
                    it.credentialId == credentialId && it.rpId == rpId
                }?.publicKeyCredentialDescriptor

            credentialDescriptor?.let {
                credMan.deleteCredential(credentialDescriptor)
                fidoViewModel.removeCredential(rpId, credentialId)
                return@useSession JSONObject(
                    mapOf(
                        "success" to true,
                    )
                ).toString()
            }

            // could not find the credential to delete
            JSONObject(
                mapOf(
                    "success" to false,
                )
            ).toString()
        }

    private fun getFingerprints(
        fidoSession: YubiKitFidoSession,
        clientPin: ClientPin,
        pinUvAuthToken: ByteArray
    ): List<FidoFingerprint> {
        val bioEnrollment =
            FingerprintBioEnrollment(fidoSession, clientPin.pinUvAuth, pinUvAuthToken)

        val enrollments: Map<ByteArray, String?> = bioEnrollment.enumerateEnrollments()
        return enrollments.map { enrollment ->
            FidoFingerprint(HexCodec.bytesToHexString(enrollment.key), enrollment.value)
        }

    }

    private suspend fun deleteFingerprint(templateId: String): String =
        connectionHelper.useSession(FidoActionDescription.DeleteFingerprint) { fidoSession ->

            val clientPin =
                ClientPin(fidoSession, getPreferredPinUvAuthProtocol(fidoSession.cachedInfo))

            val token =
                clientPin.getPinToken(
                    pinStore.getPin(),
                    getPinPermissionsBE(fidoSession),
                    null
                )


            val bioEnrollment = FingerprintBioEnrollment(fidoSession, clientPin.pinUvAuth, token)
            bioEnrollment.removeEnrollment(HexCodec.hexStringToBytes(templateId))
            fidoViewModel.removeFingerprint(templateId)
            fidoViewModel.setSessionState(Session(fidoSession.info, pinStore.hasPin(), pinRetries))
            return@useSession JSONObject(
                mapOf(
                    "success" to true,
                )
            ).toString()
        }

    private suspend fun renameFingerprint(templateId: String, name: String): String =
        connectionHelper.useSession(FidoActionDescription.RenameFingerprint) { fidoSession ->

            val clientPin =
                ClientPin(fidoSession, getPreferredPinUvAuthProtocol(fidoSession.cachedInfo))

            val token =
                clientPin.getPinToken(
                    pinStore.getPin(),
                    getPinPermissionsBE(fidoSession),
                    null
                )

            val bioEnrollment = FingerprintBioEnrollment(fidoSession, clientPin.pinUvAuth, token)
            bioEnrollment.setName(HexCodec.hexStringToBytes(templateId), name)
            fidoViewModel.renameFingerprint(templateId, name)
            fidoViewModel.setSessionState(Session(fidoSession.info, pinStore.hasPin(), pinRetries))
            return@useSession JSONObject(
                mapOf(
                    "success" to true,
                )
            ).toString()
        }

    private var state : CommandState? = null
    private fun cancelRegisterFingerprint(): String {
        state?.cancel()
        return NULL
    }

    private suspend fun registerFingerprint(name: String?): String =
        connectionHelper.useSession(FidoActionDescription.RegisterFingerprint) { fidoSession ->
            state?.cancel()
            state = CommandState()
            val clientPin =
                ClientPin(fidoSession, getPreferredPinUvAuthProtocol(fidoSession.cachedInfo))

            val token =
                clientPin.getPinToken(
                    pinStore.getPin(),
                    getPinPermissionsBE(fidoSession),
                    null
                )

            val bioEnrollment = FingerprintBioEnrollment(fidoSession, clientPin.pinUvAuth, token)

            val fingerprintEnrollmentContext = bioEnrollment.enroll(null)
            var templateId: ByteArray? = null
            while (templateId == null) {
                try {
                    templateId = fingerprintEnrollmentContext.capture(state)
                    fidoViewModel.updateRegisterFpState(
                        createCaptureEvent(fingerprintEnrollmentContext.remaining!!)
                    )
                } catch (captureError: FingerprintBioEnrollment.CaptureError) {
                    fidoViewModel.updateRegisterFpState(createCaptureErrorEvent(captureError.code))
                } catch (ctapException: CtapException) {
                    when (ctapException.ctapError) {
                        CtapException.ERR_KEEPALIVE_CANCEL -> {
                            fingerprintEnrollmentContext.cancel()
                            return@useSession JSONObject(
                                mapOf(
                                    "success" to false,
                                    "status" to "user-cancelled"
                                )
                            ).toString()
                        }
                        CtapException.ERR_USER_ACTION_TIMEOUT -> {
                            fingerprintEnrollmentContext.cancel()
                            return@useSession JSONObject(
                                mapOf(
                                    "success" to false,
                                    "status" to "user-action-timeout"
                                )
                            ).toString()
                        }
                        else -> throw ctapException
                    }
                } catch (io: IOException) {
                    return@useSession JSONObject(
                        mapOf(
                            "success" to false,
                            "status" to "connection-error"
                        )
                    ).toString()
                }
            }

            if (!name.isNullOrBlank()) {
                bioEnrollment.setName(templateId, name)
                Logger.debug(logger, "Set name to {}", name)
            }

            val templateIdHexString = HexCodec.bytesToHexString(templateId)
            fidoViewModel.addFingerprint(FidoFingerprint(templateIdHexString, name))
            fidoViewModel.setSessionState(Session(fidoSession.info, pinStore.hasPin(), pinRetries))

            return@useSession JSONObject(
                mapOf(
                    "success" to true,
                    "template_id" to templateIdHexString,
                    "name" to name
                )
            ).toString()
        }


    override fun onDisconnected() {
        if (!resetHelper.inProgress) {
            fidoViewModel.clearSessionState()
        }
    }

    override fun onTimeout() {
        fidoViewModel.clearSessionState()
    }
}