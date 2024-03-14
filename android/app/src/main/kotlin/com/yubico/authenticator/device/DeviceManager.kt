package com.yubico.authenticator.device

import androidx.collection.ArraySet
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import com.yubico.authenticator.MainViewModel
import com.yubico.authenticator.OperationContext
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.fido.FidoConnection
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.fido.ctap.Ctap2Session
import com.yubico.yubikit.oath.OathSession
import org.slf4j.LoggerFactory

interface DeviceListener {
    // a USB device is connected
    fun onConnected(device: YubiKeyDevice) {}

    // a USB device is disconnected
    fun onDisconnected() {}

    // the app has been paused for more than DeviceManager.NFC_DATA_CLEANUP_DELAY
    fun onTimeout() {}
}

class DeviceManager(
    private val lifecycleOwner: LifecycleOwner,
    private val appViewModel: MainViewModel
) {
    var clearDeviceInfoOnDisconnect: Boolean = true

    private val deviceListeners = HashSet<DeviceListener>()

    fun addDeviceListener(listener: DeviceListener) {
        deviceListeners.add(listener)
    }

    fun removeDeviceListener(listener: DeviceListener) {
        deviceListeners.remove(listener)
    }

    companion object {
        const val NFC_DATA_CLEANUP_DELAY = 30L * 1000 // 30s
        private val logger = LoggerFactory.getLogger(DeviceManager::class.java)

        fun getSupportedContexts(device: YubiKeyDevice) : ArraySet<OperationContext> = try {

            val operationContexts = ArraySet<OperationContext>()

            if (device.supportsConnection(SmartCardConnection::class.java)) {
                // try which apps are available
                device.openConnection(SmartCardConnection::class.java).use {
                    try {
                        OathSession(it)
                        operationContexts.add(OperationContext.Oath)
                    } catch (e: Throwable) { // ignored
                    }

                    try {
                        Ctap2Session(it)
                        operationContexts.add(OperationContext.FidoPasskeys)
                        operationContexts.add(OperationContext.FidoFingerprints)
                    } catch (e: Throwable) { // ignored
                    }

                }
            }

            if (device.supportsConnection(FidoConnection::class.java)) {
                device.openConnection(FidoConnection::class.java).use {
                    try {
                        Ctap2Session(it)
                        operationContexts.add(OperationContext.FidoPasskeys)
                        operationContexts.add(OperationContext.FidoFingerprints)
                    } catch (e: Throwable) { // ignored
                    }
                }
            }

            logger.debug("Device supports following contexts: {}", operationContexts)
            operationContexts
        } catch(e: Exception) {
            logger.debug("The device does not support any context. The following exception was caught: ", e)
            ArraySet<OperationContext>()
        }

        fun getPreferredContext(contexts: ArraySet<OperationContext>) : OperationContext {
            // custom sort
            for(context in contexts) {
                if (context == OperationContext.Oath) {
                    return context
                } else if (context == OperationContext.FidoPasskeys) {
                    return context
                }
            }

            return OperationContext.Oath
        }
    }

    private val lifecycleObserver = object : DefaultLifecycleObserver {
        private var startTimeMs: Long = -1

        override fun onPause(owner: LifecycleOwner) {
            startTimeMs = currentTimeMs
            super.onPause(owner)
        }

        override fun onResume(owner: LifecycleOwner) {
            super.onResume(owner)
            if (canInvoke) {
                if (appViewModel.connectedYubiKey.value == null) {
                    // no USB YubiKey is connected, reset known data on resume
                    logger.debug("Removing NFC data after resume.")
                    if (clearDeviceInfoOnDisconnect) {
                        appViewModel.setDeviceInfo(null)
                    }
                    deviceListeners.forEach { listener ->
                        listener.onTimeout()
                    }
                }
            }
        }

        private val currentTimeMs
            get() = System.currentTimeMillis()

        private val canInvoke: Boolean
            get() = startTimeMs != -1L && currentTimeMs - startTimeMs > NFC_DATA_CLEANUP_DELAY
    }

    private val usbObserver = Observer<UsbYubiKeyDevice?> { yubiKeyDevice ->
        if (yubiKeyDevice == null) {
            deviceListeners.forEach { listener ->
                listener.onDisconnected()
            }
            if (clearDeviceInfoOnDisconnect) {
                appViewModel.setDeviceInfo(null)
            }
        } else {
            deviceListeners.forEach { listener ->
                listener.onConnected(yubiKeyDevice)
            }
        }
    }

    init {
        appViewModel.connectedYubiKey.observe(lifecycleOwner, usbObserver)
        lifecycleOwner.lifecycle.addObserver(lifecycleObserver)
    }

    fun dispose() {
        lifecycleOwner.lifecycle.removeObserver(lifecycleObserver)
        appViewModel.connectedYubiKey.removeObserver(usbObserver)
    }

    fun setDeviceInfo(deviceInfo: Info?) {
        appViewModel.setDeviceInfo(deviceInfo)
    }

    fun isUsbKeyConnected(): Boolean {
        return appViewModel.connectedYubiKey.value != null
    }

    suspend fun <T> withKey(onUsb: suspend (UsbYubiKeyDevice) -> T) =
        appViewModel.connectedYubiKey.value?.let {
            onUsb(it)
        }

    suspend fun <T> withKey(onNfc: suspend () -> T, onUsb: suspend (UsbYubiKeyDevice) -> T) =
        appViewModel.connectedYubiKey.value?.let {
            onUsb(it)
        } ?: onNfc()
}