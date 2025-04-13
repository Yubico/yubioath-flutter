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
import kotlinx.coroutines.delay
import org.slf4j.LoggerFactory
import java.nio.ByteBuffer
import kotlin.experimental.and

object Workarounds {
    private val logger = LoggerFactory.getLogger("Workarounds")

    /**
     * Returns [Info] based on the input parameters. For YubiKey NEO (and older) devices
     * connected over NFC returns [Info] with correct USB capabilities.
     */
    fun getDeviceInfo(device: YubiKeyDevice, deviceInfo: DeviceInfo, pid: UsbPid?): Info {
        if (device is NfcYubiKeyDevice &&
            device.supportsConnection(SmartCardConnection::class.java) &&
            deviceInfo.version.major < 4
        ) {

            val usbInterfaces = device.getUsbInterfaces() ?: 0
            val correctDeviceInfo = deviceInfo.fixUsbCapabilities(usbInterfaces);
            return Info(
                DeviceUtil.getName(correctDeviceInfo, null),
                true, null, correctDeviceInfo
            )
        }

        val name = DeviceUtil.getName(deviceInfo, pid?.type)
        return Info(name, device is NfcYubiKeyDevice, pid?.value, deviceInfo)
    }

    /**
     * Executes [ManagementSession.setMode] with workaround for YubiKey NEO (and older devices)
     */
    fun setMode(
        session: ManagementSession,
        yubiKeyDevice: YubiKeyDevice,
        interfaces: Int,
        challengeResponseTimeout: Int,
        autoEjectTimeout: Int?
    ) {
        if (yubiKeyDevice.transport == Transport.USB && session.version.isLessThan(3, 0, 0)) {
            setModeOverFidoConnection(
                yubiKeyDevice,
                interfaces,
                challengeResponseTimeout,
                autoEjectTimeout
            )
        } else {
            session.setMode(
                Mode.getMode(interfaces),
                challengeResponseTimeout.toByte(),
                autoEjectTimeout?.toShort() ?: 0
            )
        }
    }

    /** Workaround version of [DeviceUtil.readInfo] specific for [FidoConnection].
     */
    fun readInfo(fidoConnection: FidoConnection, usbPid: UsbPid?): DeviceInfo {
        try {
            return DeviceUtil.readInfo(fidoConnection, usbPid)
        } catch (_: UnsupportedOperationException) {
            val keyType = usbPid?.type
            val version =
                if (keyType == YubiKeyType.YKP) Version(4, 0, 0) else Version(3, 0, 0)

            val supportedApps = mutableMapOf<Transport, Int?>()
            supportedApps.put(Transport.USB, Capability.U2F.bit)
            if (keyType == YubiKeyType.NEO) {
                val baseNeoApps = Capability.OTP.bit or
                        Capability.OATH.bit or
                        Capability.PIV.bit or
                        Capability.OPENPGP.bit
                supportedApps.put(Transport.USB, Capability.U2F.bit or baseNeoApps)
                supportedApps.put(Transport.NFC, supportedApps[Transport.USB])
            }

            return DeviceInfo.Builder()
                .version(version)
                .formFactor(FormFactor.USB_A_KEYCHAIN)
                .supportedCapabilities(supportedApps)
                .build().fixUsbCapabilities(usbPid?.usbInterfaces ?: 0)
        }
    }

    private fun setModeOverFidoConnection(
        yubiKeyDevice: YubiKeyDevice,
        interfaces: Int,
        challengeResponseTimeout: Int,
        autoEjectTimeout: Int?
    ) {
        yubiKeyDevice.openConnection(FidoConnection::class.java).use {
            val fidoProtocol = FidoProtocol(it)
            val data =
                ByteBuffer.allocate(4)
                    .put(Mode.getMode(interfaces).value)
                    .put(challengeResponseTimeout.toByte())
                    .putShort(autoEjectTimeout?.toShort() ?: 0)
                    .array();
            fidoProtocol.sendAndReceive(
                (0x80 or 0x40).toByte(), // CTAP_TYPE_INIT | CTAP_VENDOR_FIRST
                data,
                null
            )
        }
    }

    private fun YubiKeyDevice.getUsbInterfaces(): Int? {
        openConnection(SmartCardConnection::class.java).use {
            val protocol = SmartCardProtocol(it)
            // probe for USB interfaces
            try {
                val response = protocol.select(AppId.OTP)
                if (response[0] == 3.toByte() && response.size > 6) {
                    return Mode.entries
                        .first { mode -> mode.value == response[6] and 0b00000111 }.interfaces
                }

            } catch (_: ApplicationNotAvailableException) {
                // pass
            }
        }
        return null
    }

    /**
     * Updates device info based on the interfaces. Used in workarounds for YubiKey NEO over NFC.
     */
    private fun DeviceInfo.fixUsbCapabilities(interfaces: Int): DeviceInfo {
        val config = this.config
        val version = this.version
        val formFactor = this.formFactor

        var supportedUsbCapabilities = getSupportedCapabilities(Transport.USB)
        var supportedNfcCapabilities = getSupportedCapabilities(Transport.NFC)

        var enabledUsbCapabilities: Int? = null // we are fixing this
        var enabledNfcCapabilities: Int? = config.getEnabledCapabilities(Transport.NFC)

        // Set usbEnabled if missing (pre YubiKey 5)
        if (hasTransport(Transport.USB)) {

            var usbEnabled = supportedUsbCapabilities
            if (usbEnabled == (Capability.OTP.bit or Capability.U2F.bit or UsbInterface.CCID)) {
                // YubiKey Edge, hide unusable CCID interface from supported
                supportedUsbCapabilities = Capability.OTP.bit or Capability.U2F.bit;
            }

            if ((interfaces and UsbInterface.OTP) == 0) {
                usbEnabled = usbEnabled and Capability.OTP.bit.inv()
            }

            if ((interfaces and UsbInterface.FIDO) == 0) {
                usbEnabled = usbEnabled and (Capability.U2F.bit or Capability.FIDO2.bit).inv();
            }

            if ((interfaces and UsbInterface.CCID) == 0) {
                usbEnabled = usbEnabled and
                        (UsbInterface.CCID
                                or Capability.OATH.bit
                                or Capability.OPENPGP.bit
                                or Capability.PIV.bit).inv()
            }

            enabledUsbCapabilities = usbEnabled
        }

        val isSky = this.isSky
        val isFips = this.isFips || (version.isAtLeast(4, 4, 0) && version.isLessThan(4, 5, 0));
        val pinComplexity = this.pinComplexity;

        // Set nfc_enabled if missing (pre YubiKey 5)
        if (hasTransport(Transport.NFC) && enabledNfcCapabilities == null) {
            enabledNfcCapabilities = supportedNfcCapabilities;
        }

        // Workaround for invalid configurations.
        if (version.isAtLeast(4, 0, 0)) {
            if (formFactor == FormFactor.USB_A_NANO
                || formFactor == FormFactor.USB_C_NANO
                || formFactor == FormFactor.USB_C_LIGHTNING
                || (formFactor == FormFactor.USB_C_KEYCHAIN && version.isLessThan(5, 2, 4))
            ) {
                // Known not to have NFC
                supportedNfcCapabilities = 0
                enabledNfcCapabilities = null
            }
        }

        val deviceFlags = config.deviceFlags
        val autoEjectTimeout = config.autoEjectTimeout
        val challengeResponseTimeout = config.challengeResponseTimeout
        val isNfcRestricted = config.nfcRestricted

        val configBuilder = DeviceConfig.Builder()
        if (deviceFlags != null) {
            configBuilder.deviceFlags(deviceFlags);
        }

        if (autoEjectTimeout != null) {
            configBuilder.autoEjectTimeout(autoEjectTimeout);
        }

        if (challengeResponseTimeout != null) {
            configBuilder.challengeResponseTimeout(challengeResponseTimeout);
        }

        if (enabledNfcCapabilities != null) {
            configBuilder.enabledCapabilities(Transport.NFC, enabledNfcCapabilities);
        }

        if (enabledUsbCapabilities != null) {
            configBuilder.enabledCapabilities(Transport.USB, enabledUsbCapabilities);
        }

        configBuilder.nfcRestricted(isNfcRestricted);

        var capabilities = mutableMapOf<Transport, Int?>()
        if (supportedUsbCapabilities != 0) {
            capabilities.put(Transport.USB, supportedUsbCapabilities);
        }
        if (supportedNfcCapabilities != 0) {
            capabilities.put(Transport.NFC, supportedNfcCapabilities);
        }

        return DeviceInfo.Builder()
            .config(configBuilder.build())
            .version(version)
            .formFactor(formFactor)
            .serialNumber(serialNumber)
            .supportedCapabilities(capabilities)
            .isLocked(isLocked)
            .isFips(isFips)
            .isSky(isSky)
            .partNumber(partNumber)
            .fipsCapable(fipsCapable)
            .fipsApproved(fipsApproved)
            .pinComplexity(pinComplexity)
            .resetBlocked(resetBlocked)
            .fpsVersion(fpsVersion)
            .stmVersion(stmVersion)
            .build();
    }

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
        failureCallback: (() -> Unit)? = null,
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

