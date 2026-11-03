/*
 * Copyright (C) 2026 Yubico.
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

package com.yubico.authenticator.otp

import com.yubico.authenticator.AppContextManager
import com.yubico.authenticator.NULL
import com.yubico.authenticator.OperationContext
import com.yubico.authenticator.device.DeviceManager
import com.yubico.authenticator.jsonSerializer
import com.yubico.authenticator.otp.data.OtpState
import com.yubico.authenticator.otp.data.SlotConfig
import com.yubico.authenticator.setHandler
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.otp.OtpConnection
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.management.Capability
import com.yubico.yubikit.yubiotp.Slot
import com.yubico.yubikit.yubiotp.YubiOtpSession
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import org.slf4j.LoggerFactory

class OtpManager(
    messenger: BinaryMessenger,
    deviceManager: DeviceManager,
    private val otpViewModel: OtpViewModel
) : AppContextManager(deviceManager) {

    private val connectionHelper = OtpConnectionHelper(deviceManager)

    private val otpChannel = MethodChannel(messenger, "android.otp.methods")

    init {
        logger.debug("OtpManager initialized")

        otpChannel.setHandler(coroutineScope) { method, args ->
            @Suppress("UNCHECKED_CAST")
            when (method) {
                "swapSlots" -> swapSlots()

                "configureSlot" -> configureSlot(
                    slotFromId(args["slot"] as String),
                    args["configuration"] as Map<String, *>,
                    args["accessCode"] as String?
                )

                "deleteSlot" -> deleteSlot(
                    slotFromId(args["slot"] as String),
                    args["accessCode"] as String?
                )

                // The remaining methods are pure computation. They deliberately do not go
                // through the connection helper: requiring a YubiKey here would pop the NFC
                // overlay while the user is still filling in a dialog.
                "generateStaticPassword" -> jsonSerializer.encodeToString(
                    mapOf(
                        "password" to KeyboardLayouts.generate(
                            args["length"] as Int,
                            args["layout"] as String
                        )
                    )
                )

                "modhexEncodeSerial" -> jsonSerializer.encodeToString(
                    mapOf("encoded" to OtpUtils.modhexEncodeSerial(args["serial"] as Int))
                )

                "getKeyboardLayouts" -> jsonSerializer.encodeToString(KeyboardLayouts.layouts())

                "formatYubiOtpCsv" -> jsonSerializer.encodeToString(
                    mapOf(
                        "csv" to OtpUtils.formatYubiOtpCsv(
                            args["serial"] as Int,
                            args["publicId"] as String,
                            args["privateId"] as String,
                            args["key"] as String
                        )
                    )
                )

                else -> throw NotImplementedError()
            }
        }
    }

    override fun supports(appContext: OperationContext): Boolean =
        appContext == OperationContext.YubiOtp

    override fun activate() {
        super.activate()
        logger.debug("OtpManager activated")
    }

    override fun deactivate() {
        otpViewModel.clearState()
        connectionHelper.cancelPending()
        logger.debug("OtpManager deactivated")
        super.deactivate()
    }

    override fun onError(e: Exception) {
        super.onError(e)
        if (connectionHelper.hasPending()) {
            logger.error("Cancelling pending action. Cause: ", e)
            connectionHelper.cancelPending()
        }
    }

    override fun hasPending(): Boolean = connectionHelper.hasPending()

    override fun dispose() {
        super.dispose()
        otpChannel.setMethodCallHandler(null)
        logger.debug("OtpManager disposed")
    }

    override suspend fun processYubiKey(device: YubiKeyDevice): Boolean {
        var requestHandled = true
        try {
            val previousSerial = otpViewModel.currentSerial.value
            val (currentSerial, state) = withOtpSession(device) { session ->
                runCatching { session.serialNumber }.getOrNull() to
                    runCatching { OtpState.from(session) }.getOrNull()
            }
            otpViewModel.setSerial(currentSerial)
            logger.debug(
                "Previous serial: {}, current serial: {}",
                previousSerial,
                currentSerial
            )

            val sameDevice = previousSerial == currentSerial

            if (!sameDevice || !connectionHelper.hasPending()) {
                connectionHelper.cancelPending()
                if (state == null) {
                    logger.error("Error reading otp session.")
                    otpViewModel.clearState()
                } else {
                    otpViewModel.setState(state)
                }
            } else if (device is NfcYubiKeyDevice && connectionHelper.hasPending()) {
                requestHandled = connectionHelper.invokePending(device)
            }
        } catch (e: Exception) {
            logger.error("Cancelling pending action. Cause: ", e)
            connectionHelper.cancelPending()

            if (e !is IOException) {
                // we don't clear the session on IOExceptions so that the session is ready for
                // a possible re-run of a failed action.
                otpViewModel.clearState()
            }
            throw e
        }

        return requestHandled
    }

    /**
     * Opens a YubiOTP session over the best available transport.
     *
     * A smart card connection is preferred (and is the only option over NFC), but a USB YubiKey
     * can have CCID disabled while still exposing the OTP keyboard interface, so fall back to
     * an [OtpConnection]. SCP is only meaningful on the smart card path.
     */
    private fun <T> withOtpSession(device: YubiKeyDevice, block: (YubiOtpSession) -> T): T =
        if (device.supportsConnection(SmartCardConnection::class.java)) {
            device.openConnection(SmartCardConnection::class.java).use { connection ->
                // If OTP is FIPS capable, and we have scpKeyParams, we should use them
                val fips =
                    (deviceManager.deviceInfo?.fipsCapable ?: 0) and Capability.OTP.bit != 0
                block(
                    YubiOtpSession(
                        connection,
                        if (fips) deviceManager.scpKeyParams else null
                    )
                )
            }
        } else if (device.supportsConnection(OtpConnection::class.java)) {
            device.openConnection(OtpConnection::class.java).use { connection ->
                block(YubiOtpSession(connection))
            }
        } else {
            throw IllegalArgumentException("Device does not support any OTP connection type")
        }

    private fun updateOtpState(device: YubiKeyDevice) {
        val state = try {
            withOtpSession(device) { OtpState.from(it) }
        } catch (e: Exception) {
            logger.error("Error reading otp session. ", e)
            null
        }

        if (state == null) {
            otpViewModel.clearState()
        } else {
            otpViewModel.setState(state)
        }
    }

    private suspend fun swapSlots(): String = connectionHelper.useDevice(
        onComplete = ::updateOtpState,
        waitForNfcKeyRemoval = true
    ) { device ->
        withOtpSession(device) { it.swapConfigurations() }
        NULL
    }

    private suspend fun configureSlot(
        slot: Slot,
        configuration: Map<String, *>,
        accessCode: String?
    ): String = connectionHelper.useDevice(
        onComplete = ::updateOtpState,
        waitForNfcKeyRemoval = true
    ) { device ->
        val config = SlotConfig.fromMap(configuration)
        val currentAccessCode = accessCode?.hexToByteArray()
        withOtpSession(device) {
            // Matching the desktop helper, the current access code is also set as the new one,
            // so that programming a slot does not silently clear its protection.
            it.putConfiguration(slot, config, currentAccessCode, currentAccessCode)
        }
        NULL
    }

    private suspend fun deleteSlot(slot: Slot, accessCode: String?): String =
        connectionHelper.useDevice(
            onComplete = ::updateOtpState,
            waitForNfcKeyRemoval = true
        ) { device ->
            withOtpSession(device) {
                it.deleteConfiguration(slot, accessCode?.hexToByteArray())
            }
            NULL
        }

    companion object {
        private val logger = LoggerFactory.getLogger(OtpManager::class.java)

        /** Maps the `SlotId` identifiers used by the shared Flutter models. */
        private fun slotFromId(slotId: String): Slot = when (slotId) {
            "one" -> Slot.ONE
            "two" -> Slot.TWO
            else -> throw IllegalArgumentException("Invalid slot: $slotId")
        }
    }
}
