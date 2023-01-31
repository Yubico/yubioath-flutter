package com.yubico.authenticator.data

import com.yubico.authenticator.device.Info
import com.yubico.authenticator.logging.Log
import com.yubico.authenticator.yubikit.withConnection
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.Transport
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.support.DeviceUtil
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import java.io.IOException
import java.util.concurrent.ArrayBlockingQueue

interface ConnectionListener {
    fun onSmartCardConnection(connection: SmartCardConnection)
    fun onDisconnect()
}

interface DeviceModel {
    fun getDevice(): Flow<Info?>

    suspend fun deviceConnected(device: YubiKeyDevice)
    suspend fun deviceDisconnected()

    fun addConnectionListener(listener: ConnectionListener)
    fun removeConnectionListener(listener: ConnectionListener)
    suspend fun <T> useDevice(
        title: String,
        action: suspend (YubiKeyDevice) -> T
    ): T
}

class YubiKitDeviceModel() : DeviceModel {

    private var currentDevice: YubiKeyDevice? = null

    private val queue = ArrayBlockingQueue<Result<Info?>>(1)
    private val connectionListeners: MutableList<ConnectionListener> = ArrayList()

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

        currentDevice = device

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

                for (listener in connectionListeners) {
                    try {
                        listener.onSmartCardConnection(connection)
                    } catch (t: Throwable) {
                        Log.d(TAG, "Ajaj issues doing stuff in other models")
                    }
                }


            } catch (t: Throwable) {
                Log.d(TAG, "Adding to queue")
                queue.add(Result.failure(t))
            }

        }
    }

    override suspend fun deviceDisconnected() {

        for (listener in connectionListeners) {
            try {
                listener.onDisconnect()
            } catch (t: Throwable) {
                Log.d(TAG, "Ajaj issues doing stuff in other models")
            }
        }

        Log.d(TAG, "Device disconnected")

        currentDevice = null

        queue.add(Result.success(null))
    }


    override fun addConnectionListener(listener: ConnectionListener) {
        connectionListeners.add(listener)
    }

    override fun removeConnectionListener(listener: ConnectionListener) {
        connectionListeners.remove(listener)
    }

    // TODO: different calls for USB/NFC
    //        return appViewModel.connectedYubiKey.value?.let {
    //            useOathSessionUsb(it, action)
    //        } ?: useOathSessionNfc(title, action)
    override suspend fun <T> useDevice(title: String, action: suspend (YubiKeyDevice) -> T): T =
        currentDevice?.let {
            action(it)
        } ?: throw IOException("Device disconnected")


    companion object {
        private const val TAG = "YubiKitDeviceModel"
    }

}