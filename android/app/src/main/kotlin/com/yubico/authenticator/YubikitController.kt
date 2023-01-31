package com.yubico.authenticator

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import com.yubico.authenticator.data.DeviceRepository
import com.yubico.authenticator.logging.Log
import com.yubico.yubikit.android.YubiKitManager
import com.yubico.yubikit.android.transport.nfc.NfcConfiguration
import com.yubico.yubikit.android.transport.nfc.NfcNotAvailable
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.android.transport.usb.UsbConfiguration
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.Logger
import com.yubico.yubikit.core.YubiKeyDevice
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.launch
import java.util.concurrent.Executors

interface YubikitController {
    fun startNfcDiscovery(
        activity: Activity,
        onYubiKey: (device: NfcYubiKeyDevice) -> Unit
    )

    fun stopNfcDiscovery(activity: Activity)

    fun startUsbDiscovery(onYubiKeyDevice: (device: UsbYubiKeyDevice) -> Unit)

    fun stopUsbDiscovery()

    fun setupLogger(
        onDebug: (message: String) -> Unit,
        onError: (message: String, throwable: Throwable) -> Unit
    )

    fun getNfcTimeout(): Int

    fun verifyConnectedKeys(intent: Intent)
}

class DefaultYubikitController(
    private val applicationContext: Context,
    private val yubiKitManager: YubiKitManager,
    private val deviceRepository: DeviceRepository,
    private val appPreferences: AppPreferences
) : YubikitController {

    private val dispatcher = Executors.newSingleThreadExecutor().asCoroutineDispatcher()
    private val coroutineScope = CoroutineScope(SupervisorJob() + dispatcher)

    private val nfcConfiguration = NfcConfiguration()
    private val usbConfiguration = UsbConfiguration().handlePermissions(true)
    private var hasNfc: Boolean = false

    companion object {
        private const val TAG = "YubiKitController"
        const val YUBICO_VENDOR_ID = 4176
    }

    override fun startNfcDiscovery(
        activity: Activity,
        onYubiKey: (device: NfcYubiKeyDevice) -> Unit
    ) {
        Log.d(TAG, "Starting nfc discovery")
        hasNfc = try {
            yubiKitManager.startNfcDiscovery(
                nfcConfiguration.disableNfcDiscoverySound(appPreferences.silenceNfcSounds),
                activity

            ) { device ->
                onDeviceConnected(device)
                //onYubiKey(device) // TODO: figure out if we want to call any lambda at all
            }
            true
        } catch (nfcNotAvailable: NfcNotAvailable) {
            false
        }
    }

    override fun stopNfcDiscovery(activity: Activity) {
        if (hasNfc) {
            yubiKitManager.stopNfcDiscovery(activity)
            Log.d(TAG, "Stopped nfc discovery")
        }
    }

    override fun startUsbDiscovery(onYubiKeyDevice: (device: UsbYubiKeyDevice) -> Unit) {
        Log.d(MainActivity.TAG, "Starting usb discovery")
        yubiKitManager.startUsbDiscovery(usbConfiguration) { device ->
            onDeviceConnected(device)
            device.setOnClosed {
                coroutineScope.launch {
                    deviceRepository.deviceDisconnected()
                }
            }
            //onYubiKeyDevice(device) // TODO: figure out if we want to call any lambda at all
        }
    }

    override fun stopUsbDiscovery() {
        yubiKitManager.stopUsbDiscovery()
        Log.d(MainActivity.TAG, "Stopped usb discovery")
    }

    override fun setupLogger(
        onDebug: (message: String) -> Unit,
        onError: (message: String, throwable: Throwable) -> Unit
    ) {
        Logger.setLogger(object : Logger() {
            override fun logDebug(message: String) {
                onDebug(message)
            }

            override fun logError(message: String, throwable: Throwable) {
                onError(message, throwable)
            }
        })
    }

    override fun getNfcTimeout(): Int = nfcConfiguration.timeout


    private fun onDeviceConnected(device: YubiKeyDevice) {
        coroutineScope.launch {
            deviceRepository.deviceConnected(device)
        }
    }

    override fun verifyConnectedKeys(intent: Intent) {
        val usbManager = applicationContext.getSystemService(Context.USB_SERVICE) as UsbManager
        if (UsbManager.ACTION_USB_DEVICE_ATTACHED == intent.action) {
            val device = intent.parcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE)
            if (device != null) {
                // start the USB discover only if the user approved the app to use the device
                if (usbManager.hasPermission(device)) {
                    startUsbDiscovery { }
                }
            }
        } else {
            if (deviceRepository.isUSBDeviceConnected()) {
                // if any YubiKeys are connected, use them directly
                val deviceIterator = usbManager.deviceList.values.iterator()
                while (deviceIterator.hasNext()) {
                    val device = deviceIterator.next()
                    if (device.vendorId == YUBICO_VENDOR_ID) {
                        // the device might not have a USB permission
                        // it will be requested during during the UsbDiscovery
                        startUsbDiscovery {}
                        break
                    }
                }
            }
        }
    }
}