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

package com.yubico.authenticator.management

import com.yubico.authenticator.AppContextManager
import com.yubico.authenticator.NULL
import com.yubico.authenticator.OperationContext
import com.yubico.authenticator.device.DeviceManager
import com.yubico.authenticator.device.Info
import com.yubico.authenticator.setHandler
import com.yubico.authenticator.yubikit.DeviceInfoHelper.Companion.getDeviceInfo
import com.yubico.yubikit.core.Transport
import com.yubico.yubikit.core.UsbInterface.Mode
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.fido.FidoConnection
import com.yubico.yubikit.core.otp.OtpConnection
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.management.DeviceConfig
import com.yubico.yubikit.management.ManagementSession
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.slf4j.LoggerFactory

class ManagementManager(messenger: BinaryMessenger, deviceManager: DeviceManager) :
    AppContextManager(deviceManager) {

    private val channel = MethodChannel(messenger, "android.management.methods")
    private val connectionHelper = ManagementConnectionHelper(deviceManager)

    // DeviceInfo of the device which was connected at the execution time
    private var targetDeviceInfo: Info? = null

    init {
        logger.debug("ManagementManager initialized")
        channel.setHandler(coroutineScope) { method, args ->

            // remember current device info
            targetDeviceInfo = deviceManager.deviceInfo?.copy()

            @Suppress("UNCHECKED_CAST")
            when (method) {
                "deviceReset" -> deviceReset()

                "setMode" -> setMode(
                    args["interfaces"] as Int,
                    args["challengeResponseTimeout"] as Int,
                    args["autoEjectTimeout"] as Int?,
                )

                "configure" -> configure(
                    args["config"] as HashMap<String, *>,
                    args["currentLockCode"] as String?,
                    args["newLockCode"] as String?,
                    args["reboot"] as Boolean,
                )

                else -> throw NotImplementedError()
            }
        }
    }

    override fun supports(appContext: OperationContext): Boolean =
        appContext == OperationContext.Management

    override fun activate() {
        super.activate()
        logger.debug("ManagementManager activated")
    }

    override fun deactivate() {
        logger.debug("ManagementManager deactivated")
        targetDeviceInfo = null
        super.deactivate()
    }

    private suspend fun setMode(
        interfaces: Int,
        challengeResponseTimeout: Int,
        autoEjectTimeout: Int?
    ): String = connectionHelper.useDevice { yubikey ->
        try {
            withManagementSession(yubikey) {
                it.setMode(
                    Mode.getMode(interfaces),
                    challengeResponseTimeout.toByte(),
                    autoEjectTimeout?.toShort() ?: 0
                )
            }
            deviceManager.setDeviceInfo(runCatching { getDeviceInfo(yubikey) }.getOrNull())
            NULL
        } catch (t: Throwable) {
            logger.error("Failed to update device config: ", t)
            throw t
        }
    }

    private suspend fun configure(
        config: HashMap<String, *>,
        currentLockCode: String?,
        newLockCode: String?,
        reboot: Boolean
    ): String = connectionHelper.useDevice { yubikey ->
        try {
            withManagementSession(yubikey) {
                it.updateDeviceConfig(
                    deviceConfigFromMap(config),
                    reboot,
                    HexCodec.hexStringToBytes(currentLockCode),
                    HexCodec.hexStringToBytes(newLockCode)
                )
            }
            deviceManager.setDeviceInfo(runCatching { getDeviceInfo(yubikey) }.getOrNull())
            NULL
        } catch (t: Throwable) {
            logger.error("Failed to update device config: ", t)
            throw t
        }
    }

    private suspend fun deviceReset(): String =
        connectionHelper.useDevice { yubikey ->
            withManagementSession(yubikey) {
                it.deviceReset()
            }
            deviceManager.setDeviceInfo(runCatching { getDeviceInfo(yubikey) }.getOrNull())
            NULL
        }

    override suspend fun processYubiKey(device: YubiKeyDevice): Boolean {
        if (!hasPending()) {
            return false
        }

        val deviceChanged = targetDeviceInfo != deviceManager.deviceInfo
        targetDeviceInfo = deviceManager.deviceInfo?.copy()

        if (deviceChanged) {
            logger.warn("Device change since action started. Ignoring.")
            connectionHelper.cancelPending()
            return false
        }

        connectionHelper.invokePending(device)
        return true
    }

    private fun <T> withManagementSession(
        device: YubiKeyDevice,
        block: (ManagementSession) -> T
    ): T = if (device.supportsConnection(SmartCardConnection::class.java)) {
        device.openConnection(SmartCardConnection::class.java).use {
            block(ManagementSession(it, deviceManager.scpKeyParams))
        }
    } else if (device.supportsConnection(FidoConnection::class.java)) {
        device.openConnection(FidoConnection::class.java).use {
            block(ManagementSession(it))
        }
    } else if (device.supportsConnection(OtpConnection::class.java)) {
        device.openConnection(OtpConnection::class.java).use {
            block(ManagementSession(it))
        }
    } else throw IllegalArgumentException("Device does not support any connection type")

    override fun hasPending(): Boolean = connectionHelper.hasPending()

    companion object {
        private val logger = LoggerFactory.getLogger(ManagementManager::class.java)
        fun deviceConfigFromMap(config: HashMap<String, *>): DeviceConfig {
            val builder = DeviceConfig.Builder()
            config["device_flags"]?.let {
                if (it is Int) {
                    builder.deviceFlags(it)
                }
            }
            config["auto_eject_timeout"]?.let {
                if (it is Int) {
                    builder.autoEjectTimeout(it.toShort())
                }
            }
            config["challenge_response_timeout"]?.let {
                if (it is Int) {
                    builder.challengeResponseTimeout(it.toByte())
                }
            }
            config["enabled_capabilities"]?.let {
                if (it is HashMap<*, *>) {
                    it["usb"]?.let { capabilities ->
                        if (capabilities is Int) {
                            builder.enabledCapabilities(Transport.USB, capabilities)
                        }
                    }
                    it["nfc"]?.let { capabilities ->
                        if (capabilities is Int) {
                            builder.enabledCapabilities(Transport.NFC, capabilities)
                        }
                    }

                }
            }
            return builder.build()
        }
    }

    private object HexCodec {
        @OptIn(ExperimentalStdlibApi::class)
        fun hexStringToBytes(hex: String?): ByteArray? = hex?.let {
            try {
                if (it.isNotEmpty())
                    it.hexToByteArray()
                else
                    null
            } catch (_: IllegalArgumentException) {
                null
            }
        }
    }
}