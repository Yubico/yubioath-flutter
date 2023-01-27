package com.yubico.authenticator.data

import com.yubico.authenticator.device.Info
import com.yubico.yubikit.android.YubiKitManager
import kotlinx.coroutines.flow.Flow

interface DeviceModel {
    fun getDevice(): Flow<Info?>
}

class YubiKitDeviceModel(val yubiKitManager: YubiKitManager) : DeviceModel {


    override fun getDevice(): Flow<Info?> {
        TODO("Not yet implemented")
    }

}