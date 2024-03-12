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
import com.yubico.authenticator.asString
import com.yubico.authenticator.device.DeviceListener
import com.yubico.authenticator.device.DeviceManager
import com.yubico.authenticator.device.Info
import com.yubico.authenticator.device.UnknownDevice
import com.yubico.authenticator.fido.data.FidoCredential
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

typealias FidoAction = (Result<YubiKitFidoSession, Exception>) -> Unit

class FidoManager(
    messenger: BinaryMessenger,
    private val deviceManager: DeviceManager,
    private val fidoViewModel: FidoViewModel,
    mainViewModel: MainViewModel,
    dialogManager: DialogManager,
) : AppContextManager(), DeviceListener {

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

    private val resetHelper =
        FidoResetHelper(deviceManager, fidoViewModel, mainViewModel, connectionHelper, pinStore)

    override fun onPause() {
        resetHelper.onPause()
    }

    override fun onResume() {
        resetHelper.onResume()
    }

    init {
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

                else -> throw NotImplementedError()
            }
        }

        if (!deviceManager.isUsbKeyConnected()) {
            // for NFC connections require extra tap when switching context
            if (fidoViewModel.sessionState.value == null) {
                fidoViewModel.clearSessionState()
            }
        }

    }

    override fun dispose() {
        super.dispose()
        deviceManager.removeDeviceListener(this)
        fidoChannel.setMethodCallHandler(null)
        fidoViewModel.clearSessionState()
        fidoViewModel.clearCredentials()
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
                deviceManager.setDeviceInfo(deviceInfo)
            }

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

        val previousSession = fidoViewModel.sessionState.value?.data?.info
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
            }

            fidoViewModel.setSessionState(
                Session(
                    fidoSession.cachedInfo,
                    pinStore.hasPin()
                )
            )

            // Update deviceInfo since the deviceId has changed
            val pid = (device as? UsbYubiKeyDevice)?.pid
            val deviceInfo = DeviceUtil.readInfo(connection, pid)
            deviceManager.setDeviceInfo(
                Info(
                    name = DeviceUtil.getName(deviceInfo, pid?.type),
                    isNfc = device.transport == Transport.NFC,
                    usbPid = pid?.value,
                    deviceInfo = deviceInfo
                )
            )
        }
    }

    private fun getPermissions(fidoSession: YubiKitFidoSession): Int {
        // TODO: Add bio Enrollment permissions if supported
        return if (CredentialManagement.isSupported(fidoSession.cachedInfo))
            ClientPin.PIN_PERMISSION_CM
        else
            0
    }

    private fun unlockSession(
        fidoSession: YubiKitFidoSession,
        clientPin: ClientPin,
        pin: CharArray
    ): String {

        fidoViewModel.setSessionLoadingState()

        val permissions = getPermissions(fidoSession)

        if (permissions != 0) {
            val token = clientPin.getPinToken(pin, permissions, null)
            val credentials = getCredentials(fidoSession, clientPin, token)
            logger.debug("Creds: {}", credentials)
            fidoViewModel.updateCredentials(credentials)
        } else {
            clientPin.getPinToken(pin, permissions, "yubico-authenticator.example.com")
        }

        pinStore.setPin(pin)

        fidoViewModel.setSessionState(
            Session(
                fidoSession.cachedInfo,
                pinStore.hasPin()
            )
        )
        return JSONObject(mapOf("success" to true)).toString()
    }

    private fun catchPinErrors(clientPin: ClientPin, block: () -> String): String =
        try {
            block()
        } catch (ctapException: CtapException) {
            if (ctapException.ctapError == CtapException.ERR_PIN_INVALID ||
                ctapException.ctapError == CtapException.ERR_PIN_BLOCKED ||
                ctapException.ctapError == CtapException.ERR_PIN_AUTH_BLOCKED
            ) {
                pinStore.setPin(null)
                fidoViewModel.clearCredentials()
                val pinRetriesResult = clientPin.pinRetries
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
        connectionHelper.useSession(FidoActionDescription.Unlock) { fidoSession ->

            try {
                val clientPin =
                    ClientPin(fidoSession, getPreferredPinUvAuthProtocol(fidoSession.cachedInfo))

                catchPinErrors(clientPin) {
                    unlockSession(fidoSession, clientPin, pin)
                }

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

                catchPinErrors(clientPin) {
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

            fidoViewModel.setCredentialsLoadingState()

            val credMan = CredentialManagement(fidoSession, clientPin.pinUvAuth, pinUvAuthToken)
            val rpIds = credMan.enumerateRps()

            val credentials = rpIds.map { rpData ->
                credMan.enumerateCredentials(rpData.rpIdHash).map { credentialData ->
                    FidoCredential(
                        rpData.rp["id"] as String,
                        (credentialData.credentialId["id"] as ByteArray).asString(),
                        (credentialData.user["id"] as ByteArray).asString(),
                        credentialData.user["name"] as String,
                        publicKeyCredentialDescriptor = credentialData.credentialId
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

            val permissions = getPermissions(fidoSession)

            val token = clientPin.getPinToken(pinStore.getPin(), permissions, null)

            val credMan = CredentialManagement(fidoSession, clientPin.pinUvAuth, token)

            val credentialDescriptor =
                fidoViewModel.credentials.value?.data?.firstOrNull {
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

    override fun onDisconnected() {
        if (!resetHelper.inProgress) {
            fidoViewModel.clearSessionState()
        }
    }

    override fun onTimeout() {
        fidoViewModel.clearSessionState()
    }
}