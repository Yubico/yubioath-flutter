package com.yubico.authenticator

import android.content.*
import android.content.pm.PackageManager
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.viewModels
import androidx.core.view.WindowCompat
import androidx.lifecycle.lifecycleScope
import com.yubico.authenticator.logging.FlutterLog
import com.yubico.authenticator.logging.Log
import com.yubico.authenticator.oath.OathManager
import com.yubico.authenticator.oath.OathViewModel
import com.yubico.yubikit.android.YubiKitManager
import com.yubico.yubikit.android.transport.nfc.NfcConfiguration
import com.yubico.yubikit.android.transport.nfc.NfcNotAvailable
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.android.transport.usb.UsbConfiguration
import com.yubico.yubikit.core.Logger
import com.yubico.yubikit.core.YubiKeyDevice
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.launch
import java.io.Closeable
import java.util.concurrent.Executors

class MainActivity : FlutterFragmentActivity() {
    private val viewModel: MainViewModel by viewModels()
    private val oathViewModel: OathViewModel by viewModels()

    private val nfcConfiguration = NfcConfiguration()

    private var hasNfc: Boolean = false

    private lateinit var yubikit: YubiKitManager

    // receives broadcasts when QR Scanner camera is closed
    private val qrScannerCameraClosedBR = QRScannerCameraClosedBR()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)

        allowScreenshots(false)

        yubikit = YubiKitManager(this)

        setupYubiKitLogger()
    }

    /**
     * Enables or disables .AliasMainActivity component. This activity alias adds intent-filter
     * for android.hardware.usb.action.USB_DEVICE_ATTACHED. When enabled, the app will be opened
     * when a compliant USB device (defined in `res/xml/device_filter.xml`) is attached.
     *
     * By default the activity alias is disabled through AndroidManifest.xml.
     *
     * @param enable if true, alias activity will be enabled
     */
    private fun enableAliasMainActivityComponent(enable: Boolean) {
        val componentName = ComponentName(packageName, "com.yubico.authenticator.AliasMainActivity")
        applicationContext.packageManager.setComponentEnabledSetting(
            componentName,
            if (enable)
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            else
                PackageManager.COMPONENT_ENABLED_STATE_DEFAULT,
            PackageManager.DONT_KILL_APP
        )
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    private fun startNfcDiscovery() =
        try {
            Log.d(TAG, "Starting nfc discovery")
            yubikit.startNfcDiscovery(nfcConfiguration, this, ::processYubiKey)
            hasNfc = true
        } catch (e: NfcNotAvailable) {
            hasNfc = false
        }

    private fun stopNfcDiscovery() {
        if (hasNfc) {
            yubikit.stopNfcDiscovery(this)
            Log.d(TAG, "Stopped nfc discovery")
        }
    }

    private fun startUsbDiscovery() {
        Log.d(TAG, "Starting usb discovery")
        val usbConfiguration = UsbConfiguration().handlePermissions(true)
        yubikit.startUsbDiscovery(usbConfiguration) { device ->
            viewModel.setConnectedYubiKey(device) {
                Log.d(TAG, "YubiKey was disconnected, stopping usb discovery")
                stopUsbDiscovery()
            }
            processYubiKey(device)
        }
    }

    private fun stopUsbDiscovery() {
        yubikit.stopUsbDiscovery()
        Log.d(TAG, "Stopped usb discovery")
    }

    private fun setupYubiKitLogger() {
        Logger.setLogger(object : Logger() {
            private val TAG = "yubikit"

            override fun logDebug(message: String) {
                // redirect yubikit debug logs to traffic
                Log.t(TAG, message)
            }

            override fun logError(message: String, throwable: Throwable) {
                Log.e(TAG, message, throwable.message ?: throwable.toString())
            }
        })
    }

    override fun onStart() {
        super.onStart()
        registerReceiver(qrScannerCameraClosedBR, QRScannerCameraClosedBR.intentFilter)
    }

    override fun onStop() {
        super.onStop()
        unregisterReceiver(qrScannerCameraClosedBR)
    }

    override fun onPause() {
        stopNfcDiscovery()
        enableAliasMainActivityComponent(false)
        super.onPause()
    }

    override fun onResume() {
        super.onResume()

        enableAliasMainActivityComponent(true)

        // Handle existing tag when launched from NDEF
        val tag = intent.getParcelableExtra<Tag>(NfcAdapter.EXTRA_TAG)
        if (tag != null) {
            intent.removeExtra(NfcAdapter.EXTRA_TAG)

            val executor = Executors.newSingleThreadExecutor()
            val device = NfcYubiKeyDevice(tag, nfcConfiguration.timeout, executor)
            lifecycleScope.launch {
                try {
                    contextManager?.processYubiKey(device)
                    device.remove {
                        executor.shutdown()
                        startNfcDiscovery()
                    }
                } catch (e: Throwable) {
                    Log.e(TAG, "Error processing YubiKey in AppContextManager", e.toString())
                }
            }
        } else {
            startNfcDiscovery()
        }

        val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
        if (UsbManager.ACTION_USB_DEVICE_ATTACHED == intent.action) {
            val device = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE) as UsbDevice?
            if (device != null) {
                // start the USB discover only if the user approved the app to use the device
                if (usbManager.hasPermission(device)) {
                    startUsbDiscovery()
                }
            }
        } else if (viewModel.connectedYubiKey.value == null) {
            // if any YubiKeys are connected, use them directly
            val deviceIterator = usbManager.deviceList.values.iterator()
            while (deviceIterator.hasNext()) {
                val device = deviceIterator.next()
                if (device.vendorId == YUBICO_VENDOR_ID) {
                    // the device might not have a USB permission
                    // it will be requested during during the UsbDiscovery
                    startUsbDiscovery()
                    break
                }
            }
        }
    }

    private fun processYubiKey(device: YubiKeyDevice) {
        contextManager?.let {
            lifecycleScope.launch {
                try {
                    it.processYubiKey(device)
                } catch (e: Throwable) {
                    Log.e(TAG, "Error processing YubiKey in AppContextManager", e.toString())
                }
            }
        }
    }

    private var contextManager: AppContextManager? = null
    private lateinit var appContext: AppContext
    private lateinit var dialogManager: DialogManager
    private lateinit var appPreferences: AppPreferences
    private lateinit var flutterLog: FlutterLog
    private lateinit var flutterStreams: List<Closeable>
    private lateinit var appMethodChannel: AppMethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        flutterLog = FlutterLog(messenger)
        appContext = AppContext(messenger, this.lifecycleScope, viewModel)
        dialogManager = DialogManager(messenger, this.lifecycleScope)
        appPreferences = AppPreferences(this)
        appMethodChannel = AppMethodChannel(messenger)

        flutterStreams = listOf(
            viewModel.deviceInfo.streamTo(this, messenger, "android.devices.deviceInfo"),
            oathViewModel.sessionState.streamTo(this, messenger, "android.oath.sessionState"),
            oathViewModel.credentials.streamTo(this, messenger, "android.oath.credentials"),
        )

        viewModel.appContext.observe(this) {
            contextManager?.dispose()
            contextManager = when (it) {
                OperationContext.Oath -> OathManager(
                    this,
                    messenger,
                    viewModel,
                    oathViewModel,
                    dialogManager,
                    appPreferences
                )
                else -> null
            }
            viewModel.connectedYubiKey.value?.let(::processYubiKey)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        flutterStreams.forEach { it.close() }
        super.cleanUpFlutterEngine(flutterEngine)
    }

    companion object {
        const val TAG = "MainActivity"
        const val YUBICO_VENDOR_ID = 4176
        const val FLAG_SECURE = WindowManager.LayoutParams.FLAG_SECURE
    }

    /** We observed that some devices (Pixel 2, OnePlus 6) automatically end NFC discovery
     * during the use of device camera when scanning QR codes. To handle NFC events correctly,
     * this receiver restarts the YubiKit NFC discovery when the QR Scanner camera is closed.
     */
    class QRScannerCameraClosedBR : BroadcastReceiver() {
        companion object {
            val intentFilter = IntentFilter("com.yubico.authenticator.QRScannerView.CameraClosed")
        }

        override fun onReceive(context: Context?, intent: Intent?) {
            (context as? MainActivity)?.startNfcDiscovery()
        }
    }

    inner class AppMethodChannel(messenger: BinaryMessenger) {

        private val methodChannel = MethodChannel(messenger, "app.methods")

        init {
            methodChannel.setMethodCallHandler { methodCall, result ->
                when (methodCall.method) {
                    "allowScreenshots" -> result.success(
                        allowScreenshots(
                            methodCall.arguments as Boolean,
                        )
                    )
                    else -> Log.w(TAG, "Unknown app method: ${methodCall.method}")
                }
            }
        }
    }

    private fun allowScreenshots(value: Boolean): Boolean {
        // Note that FLAG_SECURE is the inverse of allowScreenshots
        if (value) {
            Log.d(TAG, "Clearing FLAG_SECURE (allow screenshots)")
            window.clearFlags(FLAG_SECURE)
        } else {
            Log.d(TAG, "Setting FLAG_SECURE (disallow screenshots)")
            window.setFlags(FLAG_SECURE, FLAG_SECURE)
        }

        return FLAG_SECURE != (window.attributes.flags and FLAG_SECURE)
    }

}
