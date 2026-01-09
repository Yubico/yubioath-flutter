/*
 * Copyright (C) 2025 Yubico.
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

package com.yubico.authenticator.yubikit

import com.yubico.authenticator.device.DeviceManager
import com.yubico.authenticator.device.Info
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.Transport
import com.yubico.yubikit.core.UsbInterface
import com.yubico.yubikit.core.UsbInterface.Mode
import com.yubico.yubikit.core.UsbPid
import com.yubico.yubikit.core.Version
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.YubiKeyType
import com.yubico.yubikit.core.application.ApplicationNotAvailableException
import com.yubico.yubikit.core.fido.FidoConnection
import com.yubico.yubikit.core.fido.FidoProtocol
import com.yubico.yubikit.core.smartcard.AppId
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.smartcard.SmartCardProtocol
import com.yubico.yubikit.management.Capability
import com.yubico.yubikit.management.DeviceConfig
import com.yubico.yubikit.management.DeviceInfo
import com.yubico.yubikit.management.FormFactor
import com.yubico.yubikit.management.ManagementSession
import com.yubico.yubikit.support.DeviceUtil
import java.nio.ByteBuffer
import kotlinx.coroutines.delay
import org.slf4j.LoggerFactory

object Workarounds {
    private val logger = LoggerFactory.getLogger("Workarounds")

    /**
     * Send CTAPHID_PING several times to probe whether the device is in the USB reclaim state.
     * @return true if the reclaim time is over and communication over FidoConnection is possible and
     * false if the communication with the key over FidoConnection failed after several tries.
     */
    suspend fun handleUsbReclaim(
        deviceManager: DeviceManager,
        device: YubiKeyDevice,
        enterReclaimCallback: (() -> Unit)? = null,
        leaveReclaimCallback: (() -> Unit)? = null,
        failureCallback: (() -> Unit)? = null
    ) = when {
        device !is UsbYubiKeyDevice -> true

        device.pid !in arrayOf(
            UsbPid.NEO_OTP_FIDO,
            UsbPid.YK4_OTP_FIDO
        ) -> true

        else -> {
            enterReclaimCallback?.invoke()
            run repeatBlock@{
                repeat(10) {
                    if (canPing(device)) {
                        logger.info("USB reclaim period is over")
                        leaveReclaimCallback?.invoke()
                        return true
                    }
                    delay(500)
                    if (!deviceManager.isUsbKeyConnected()) {
                        logger.debug("Key was disconnected during reclaim testing")
                        return@repeatBlock
                    }
                }
            }
            failureCallback?.invoke()
            false
        }
    }

    /** Send CTAPHID_PING over FidoConnection
     * @return true if the command succeeded
     */
    private suspend fun canPing(usbYubiKey: UsbYubiKeyDevice) =
        usbYubiKey.withConnection<FidoConnection, Boolean> { connection ->
            try {
                FidoProtocol(connection)
                    .sendAndReceive(
                        (0x80 or 0x01).toByte(), // CTAPHID_PING
                        "Probing".toByteArray(),
                        null
                    )

                true
            } catch (exception: Exception) {
                logger.debug("Ignored exception: {}", exception.message)
                false
            }
        }
}
