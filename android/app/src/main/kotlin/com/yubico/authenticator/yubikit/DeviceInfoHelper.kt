/*
 * Copyright (C) 2022-2023 Yubico.
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

import com.yubico.authenticator.device.Info
import com.yubico.authenticator.compatUtil
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.fido.FidoConnection
import com.yubico.yubikit.core.otp.OtpConnection
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.management.DeviceInfo
import com.yubico.yubikit.support.DeviceUtil

import org.slf4j.LoggerFactory

suspend fun getDeviceInfo(device: YubiKeyDevice): Info {
    val pid = (device as? UsbYubiKeyDevice)?.pid
    val logger = LoggerFactory.getLogger("getDeviceInfo")

    val deviceInfo = runCatching {
        device.withConnection<SmartCardConnection, DeviceInfo> { DeviceUtil.readInfo(it, pid) }
    }.recoverCatching { t ->
        logger.debug("Smart card connection not available: {}", t.message)
        device.withConnection<OtpConnection, DeviceInfo> { DeviceUtil.readInfo(it, pid) }
    }.recoverCatching { t ->
        logger.debug("OTP connection not available: {}", t.message)
        device.withConnection<FidoConnection, DeviceInfo> { DeviceUtil.readInfo(it, pid) }
    }.recoverCatching { t ->
        logger.debug("FIDO connection not available: {}", t.message)
        return SkyHelper(compatUtil).getDeviceInfo(device)
    }.getOrElse {
        logger.debug("Failed to recognize device: {}", it.message)
        throw it
    }

    val name = DeviceUtil.getName(deviceInfo, pid?.type)
    return Info(name, device is NfcYubiKeyDevice, pid?.value, deviceInfo)
}