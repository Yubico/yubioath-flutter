package com.yubico.authenticator.data

import com.yubico.authenticator.device.Info
import com.yubico.yubikit.core.YubiKeyDevice
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext

interface DeviceRepository {
    val device: Flow<Info?>

    suspend fun deviceConnected(device: YubiKeyDevice)
    suspend fun deviceDisconnected()

    fun isDeviceConnected() : Boolean

    fun isUSBDeviceConnected() : Boolean
}

class DefaultDeviceRepository(private val deviceModel: DeviceModel, private val oathModel: OathModel) : DeviceRepository {

    private var deviceIsConnected = false
    private var usbDeviceIsConnected = false

    override val device: Flow<Info?>
        get() = deviceModel.getDevice().map { deviceInfo ->
            if (deviceInfo != null) {
                deviceIsConnected = true
                usbDeviceIsConnected = !deviceInfo.isNfc
            } else {
                deviceIsConnected = false
            }
            deviceInfo
        }

    override suspend fun deviceConnected(device: YubiKeyDevice) = withContext(Dispatchers.IO) {
        deviceModel.deviceConnected(device)
    }

    override suspend fun deviceDisconnected() {
        deviceModel.deviceDisconnected()
    }

    override fun isDeviceConnected() : Boolean {
        return deviceIsConnected
    }

    override fun isUSBDeviceConnected() : Boolean {
        return usbDeviceIsConnected
    }

}