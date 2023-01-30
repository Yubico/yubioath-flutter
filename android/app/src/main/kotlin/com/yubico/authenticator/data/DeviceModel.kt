package com.yubico.authenticator.data

import com.yubico.authenticator.device.Info
import com.yubico.authenticator.logging.Log
import com.yubico.authenticator.yubikit.withConnection
import com.yubico.yubikit.android.YubiKitManager
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.Transport
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.support.DeviceUtil
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import java.util.concurrent.ArrayBlockingQueue

interface DeviceModel {
    fun getDevice(): Flow<Info?>

    suspend fun deviceConnected(device: YubiKeyDevice)
    suspend fun deviceDisconnected()
}

class YubiKitDeviceModel(val yubiKitManager: YubiKitManager) : DeviceModel {

    private val queue = ArrayBlockingQueue<Result<Info?>>(1)

    init {

    }

    override fun getDevice(): Flow<Info?> = flow {
        while (true) {
            Log.d(TAG, "Taking from queue")
            val result = queue.take()
            Log.d(TAG, "Got something")
            if (result.isSuccess) {
                Log.d(TAG, "Emitting device ${result.getOrThrow()}")
            }
            emit(result.getOrNull())
        }
    }.flowOn(Dispatchers.IO)

    override suspend fun deviceConnected(device: YubiKeyDevice) {
        Log.d(TAG, "Device connected")

        device.withConnection<SmartCardConnection, Unit> { connection ->

            try {
                val pid = (device as? UsbYubiKeyDevice)?.pid
                val deviceInfo = DeviceUtil.readInfo(connection, pid)
                Log.d(TAG, "Adding to queue")
                queue.add(
                    Result.success(
                        Info(
                            name = DeviceUtil.getName(deviceInfo, pid?.type),
                            isNfc = device.transport == Transport.NFC,
                            usbPid = pid?.value,
                            deviceInfo = deviceInfo
                        )
                    )
                )
            } catch (t: Throwable) {
                Log.d(TAG, "Adding to queue")
                queue.add(Result.failure(t))
            }
        }
    }

    override suspend fun deviceDisconnected() {
        Log.d(TAG, "Device disconnected")
        queue.add(Result.success(null))
    }

    companion object {
        private const val TAG = "YubiKitDeviceModel"
    }

}