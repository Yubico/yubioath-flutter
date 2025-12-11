/*
 * Copyright (C) 2024-2025 Yubico.
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

package com.yubico.authenticator.device

import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import com.yubico.authenticator.MainActivity
import com.yubico.authenticator.MainViewModel
import com.yubico.authenticator.NfcOverlayManager
import com.yubico.authenticator.yubikit.NfcState
import com.yubico.authenticator.yubikit.Workarounds
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.smartcard.scp.ScpKeyParams
import java.io.IOException
import java.util.concurrent.atomic.AtomicReference
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
    private val appViewModel: MainViewModel,
    private val appMethodChannel: MainActivity.AppMethodChannel,
    private val nfcOverlayManager: NfcOverlayManager
) {
    var clearDeviceInfoOnDisconnect: Boolean = true

    private val deviceListeners = HashSet<DeviceListener>()

    private val _deviceInfo = AtomicReference<Info?>()
    val deviceInfo: Info?
        get() = _deviceInfo.get()

    var scpKeyParams: ScpKeyParams? = null
        set(value) {
            field = value
            logger.debug("SCP params set to {}", value)
        }

    fun addDeviceListener(listener: DeviceListener) {
        deviceListeners.add(listener)
    }

    fun removeDeviceListener(listener: DeviceListener) {
        deviceListeners.remove(listener)
    }

    companion object {
        const val NFC_DATA_CLEANUP_DELAY = 30L * 1000 // 30s
        private val logger = LoggerFactory.getLogger(DeviceManager::class.java)
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
        clearDeviceInfoOnDisconnect = true
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
        _deviceInfo.set(deviceInfo?.copy())
        appViewModel.setDeviceInfo(this.deviceInfo)
    }

    fun isUsbKeyConnected(): Boolean = appViewModel.connectedYubiKey.value != null

    suspend fun <T> withKey(onUsb: suspend (UsbYubiKeyDevice) -> T) =
        appViewModel.connectedYubiKey.value?.let {
            onUsb(it)
        }

    suspend fun <T> withKey(
        onUsb: suspend (UsbYubiKeyDevice) -> T,
        onNfc: suspend () -> com.yubico.yubikit.core.util.Result<T, Throwable>,
        onCancelled: () -> Unit
    ): T = appViewModel.connectedYubiKey.value?.let {
        if (!handleUsbReclaim(it)) {
            throw IOException("Failed handling USB reclaim")
        }
        onUsb(it)
    } ?: onNfc(onNfc, onCancelled)

    /**
     * Waits for a possible USB reclaim period to be over.
     * @return true if it was possible to communicate with the device.
     */
    suspend fun handleUsbReclaim(device: YubiKeyDevice): Boolean =
        Workarounds.handleUsbReclaim(this, device, enterReclaimCallback = {
            appMethodChannel.nfcStateChanged(NfcState.USB_ACTIVITY_ONGOING)
        }, leaveReclaimCallback = {
            appMethodChannel.nfcStateChanged(NfcState.USB_ACTIVITY_SUCCESS)
        }, failureCallback = {
            appMethodChannel.nfcStateChanged(NfcState.USB_ACTIVITY_FAILURE)
        })

    private suspend fun <T> onNfc(
        onNfc: suspend () -> com.yubico.yubikit.core.util.Result<T, Throwable>,
        onCancelled: () -> Unit
    ): T {
        nfcOverlayManager.show {
            logger.debug("NFC action was cancelled")
            onCancelled.invoke()
        }

        try {
            return onNfc.invoke().value.also {
                appMethodChannel.nfcStateChanged(NfcState.getSuccessState())
            }
        } catch (e: Exception) {
            appMethodChannel.nfcStateChanged(NfcState.getFailureState())
            throw e
        }
    }
}
