package com.yubico.authenticator.yubikit

import com.yubico.authenticator.device.Info
import com.yubico.authenticator.logging.Log
import com.yubico.authenticator.management.model
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
    }.onFailure {
        Log.d(OathManager.TAG, "Smart card connection not available")
        device.withConnection<OtpConnection, DeviceInfo> { DeviceUtil.readInfo(it, pid) }
    }.onFailure {
        Log.d(OathManager.TAG, "OTP connection not available")
        device.withConnection<FidoConnection, DeviceInfo> { DeviceUtil.readInfo(it, pid) }
    }.getOrElse {
        Log.e(OathManager.TAG, "No connection available for getting device info")
        throw it
    }

    val name = DeviceUtil.getName(deviceInfo, pid?.type)
    return deviceInfo.model(name, device is NfcYubiKeyDevice, pid?.value)
}