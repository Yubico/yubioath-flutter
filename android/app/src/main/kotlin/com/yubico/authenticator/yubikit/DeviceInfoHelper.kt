/*
 * Copyright (C) 2022-2025 Yubico.
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

import com.yubico.authenticator.compatUtil
import com.yubico.authenticator.device.Info
import com.yubico.authenticator.device.restrictedNfcDeviceInfo
import com.yubico.authenticator.device.unknownDeviceWithCapability
import com.yubico.authenticator.device.unknownFido2DeviceInfo
import com.yubico.authenticator.device.unknownOathDeviceInfo
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.Version
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.application.ApplicationNotAvailableException
import com.yubico.yubikit.core.application.SessionVersionOverride
import com.yubico.yubikit.core.fido.FidoConnection
import com.yubico.yubikit.core.otp.OtpConnection
import com.yubico.yubikit.core.smartcard.Apdu
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.smartcard.SmartCardProtocol
import com.yubico.yubikit.fido.ctap.Ctap2Session
import com.yubico.yubikit.oath.OathSession
import com.yubico.yubikit.support.DeviceUtil
import org.slf4j.LoggerFactory

class DeviceInfoHelper {
    companion object {
        private val logger = LoggerFactory.getLogger("DeviceInfoHelper")
        private val nfcTagReaderAid = byteArrayOf(0xD2.toByte(), 0x76, 0, 0, 0x85.toByte(), 1, 1)
        private val uri = "yubico.com/getting-started".toByteArray()
        private val restrictedNfcBytes =
            byteArrayOf(0x00, 0x1F, 0xD1.toByte(), 0x01, 0x1b, 0x55, 0x04) + uri

        fun getDeviceInfo(device: YubiKeyDevice): Info {
            SessionVersionOverride.set(null)
            var deviceInfo = readDeviceInfo(device)
            if (deviceInfo.version.major == 0.toByte()) {
                SessionVersionOverride.set(Version(5, 7, 2))
                deviceInfo = readDeviceInfo(device)
            }
            return deviceInfo
        }

        private fun readDeviceInfo(device: YubiKeyDevice): Info {
            val pid = (device as? UsbYubiKeyDevice)?.pid

            val deviceInfo = runCatching {
                device.openConnection(SmartCardConnection::class.java)
                    .use { DeviceUtil.readInfo(it, pid) }
            }.recoverCatching { t ->
                logger.debug("SmartCard connection not available: {}", t.message)
                device.openConnection(FidoConnection::class.java)
                    .use { Workarounds.readInfo(it, pid) }
            }.recoverCatching { t ->
                logger.debug("FIDO connection not available: {}", t.message)
                device.openConnection(OtpConnection::class.java)
                    .use { DeviceUtil.readInfo(it, pid) }
            }.recoverCatching { t ->
                logger.debug("OTP connection not available: {}", t.message)
                return SkyHelper(compatUtil).getDeviceInfo(device)
            }.getOrElse {
                // this is not a YubiKey
                logger.debug("Probing unknown device")
                try {
                    device.openConnection(SmartCardConnection::class.java)
                        .use { smartCardConnection ->
                            try {
                                // if OATH session is available use it
                                OathSession(smartCardConnection)
                                logger.debug("Device supports OATH")
                                return unknownOathDeviceInfo(device.transport)
                            } catch (_: ApplicationNotAvailableException) {
                                try {
                                    // probe for CTAP2 availability
                                    Ctap2Session(smartCardConnection)
                                    logger.debug("Device supports FIDO2")
                                    return unknownFido2DeviceInfo(device.transport)
                                } catch (_: ApplicationNotAvailableException) {
                                    // probe for NFC restricted device
                                    if (isNfcRestricted(smartCardConnection)) {
                                        logger.debug("Device has restricted NFC")
                                        return restrictedNfcDeviceInfo(device.transport)
                                    }
                                    logger.debug("Device not recognized")
                                    return unknownDeviceWithCapability(device.transport)
                                }
                            }
                        }
                } catch (e: Exception) {
                    // no smart card connectivity
                    logger.error("Failure getting device info: ", e)
                    throw e
                }
            }

            return Workarounds.getDeviceInfo(device, deviceInfo, pid)
        }

        private fun isNfcRestricted(connection: SmartCardConnection): Boolean =
            restrictedNfcBytes.contentEquals(readNdef(connection).also {
                logger.debug("ndef: {}", it)
            })

        private fun readNdef(connection: SmartCardConnection): ByteArray? = try {
            with(SmartCardProtocol(connection)) {
                select(nfcTagReaderAid)
                sendAndReceive(Apdu(0x00, 0xA4, 0x00, 0x0C, byteArrayOf(0xE1.toByte(), 0x04)))
                sendAndReceive(Apdu(0x00, 0xB0, 0x00, 0x00, null))
            }
        } catch (e: Exception) {
            logger.debug("Failed to read ndef tag: ", e)
            null
        }
    }

}

