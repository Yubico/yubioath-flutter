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
import com.yubico.authenticator.logging.Log
import com.yubico.authenticator.oath.OathManager
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.fido.FidoConnection
import com.yubico.yubikit.core.otp.OtpConnection
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.management.DeviceInfo
import com.yubico.yubikit.support.DeviceUtil

suspend fun getDeviceInfo(device: YubiKeyDevice): Info {
    val pid = (device as? UsbYubiKeyDevice)?.pid

    val deviceInfo = runCatching {
        device.withConnection<SmartCardConnection, DeviceInfo> { DeviceUtil.readInfo(it, pid) }
    }.recoverCatching {
        Log.d(OathManager.TAG, "Smart card connection not available")
        device.withConnection<OtpConnection, DeviceInfo> { DeviceUtil.readInfo(it, pid) }
    }.recoverCatching {
        Log.d(OathManager.TAG, "OTP connection not available")
        device.withConnection<FidoConnection, DeviceInfo> { DeviceUtil.readInfo(it, pid) }
    }.recoverCatching {
        Log.d(OathManager.TAG, "FIDO connection not available")
        return SkyHelper.getDeviceInfo(device)
    }.getOrElse {
        Log.e(OathManager.TAG, "Failed to recognize device")
        throw it
    }

    val name = DeviceUtil.getName(deviceInfo, pid?.type)
    return Info(name, device is NfcYubiKeyDevice, pid?.value, deviceInfo)
}