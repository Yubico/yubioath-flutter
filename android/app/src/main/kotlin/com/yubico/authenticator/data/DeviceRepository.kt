package com.yubico.authenticator.data

import com.yubico.authenticator.device.Info
import com.yubico.yubikit.core.YubiKeyDevice
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.withContext

interface DeviceRepository {
    val device: Flow<Info?>

    suspend fun deviceConnected(device: YubiKeyDevice)
    suspend fun deviceDisconnected()
}

class DefaultDeviceRepository(private val deviceModel: DeviceModel) : DeviceRepository {
    override val device: Flow<Info?>
        get() = deviceModel.getDevice()

    override suspend fun deviceConnected(device: YubiKeyDevice) = withContext(Dispatchers.IO) {
        deviceModel.deviceConnected(device)
    }

    override suspend fun deviceDisconnected() {
        deviceModel.deviceDisconnected()
    }
}