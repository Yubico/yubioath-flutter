package com.yubico.authenticator.yubikit

import com.yubico.authenticator.device.Info
import com.yubico.authenticator.logging.Log
import com.yubico.authenticator.management.model
import com.yubico.authenticator.oath.OathManager
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.support.DeviceUtil

suspend fun getDeviceInfo(device: YubiKeyDevice): Info =
    try {
        withSmartCardConnection(device) {
            val pid = (device as? UsbYubiKeyDevice)?.pid
            val deviceInfo = DeviceUtil.readInfo(it, pid)
            val name = DeviceUtil.getName(deviceInfo, pid?.type)
            deviceInfo.model(name, device is NfcYubiKeyDevice, pid?.value)
        }
    } catch (exception: Exception) {
        Log.d(OathManager.TAG, "Smart card connection not available")
        try {
            withOTPConnection(device) {
                val pid = (device as? UsbYubiKeyDevice)?.pid
                val deviceInfo = DeviceUtil.readInfo(it, pid)
                val name = DeviceUtil.getName(deviceInfo, pid?.type)
                deviceInfo.model(name, device is NfcYubiKeyDevice, pid?.value)
            }
        } catch (exception: Exception) {
            Log.d(OathManager.TAG, "OTP connection not available")
            try {
                withFidoConnection(device) {
                    val pid = (device as? UsbYubiKeyDevice)?.pid
                    val deviceInfo = DeviceUtil.readInfo(it, pid)
                    val name = DeviceUtil.getName(deviceInfo, pid?.type)
                    deviceInfo.model(name, device is NfcYubiKeyDevice, pid?.value)
                }
            } catch (exception: Exception) {
                Log.e(OathManager.TAG, "No connection available for getting device info")
                throw exception
            }
        }
    }