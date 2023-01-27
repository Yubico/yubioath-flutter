package com.yubico.authenticator.data

import com.yubico.authenticator.device.Info
import kotlinx.coroutines.flow.Flow

interface DeviceRepository {
    val device: Flow<Info?>
}

class DefaultDeviceRepository(private val deviceModel: DeviceModel) : DeviceRepository {
    override val device: Flow<Info?>
        get() = deviceModel.getDevice()
}