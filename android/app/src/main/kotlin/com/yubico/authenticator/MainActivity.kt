package com.yubico.authenticator

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.nfc.NfcAdapter
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.viewModels
import androidx.lifecycle.lifecycleScope
import com.yubico.authenticator.Constants.Companion.EXTRA_OPENED_THROUGH_NFC
import com.yubico.authenticator.logging.FlutterLog
import com.yubico.authenticator.logging.Log
import com.yubico.authenticator.oath.OathManager
import com.yubico.yubikit.android.YubiKitManager
import com.yubico.yubikit.android.transport.nfc.NfcConfiguration
import com.yubico.yubikit.android.transport.nfc.NfcNotAvailable
import com.yubico.yubikit.android.transport.usb.UsbConfiguration
import com.yubico.yubikit.core.Logger
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlin.properties.Delegates

class MainActivity : FlutterFragmentActivity() {
    private val viewModel: MainViewModel by viewModels()
    private val nfcConfiguration = NfcConfiguration()

    private var hasNfc by Delegates.notNull<Boolean>()

    private lateinit var yubikit: YubiKitManager

    // receives broadcasts when QR Scanner camera is closed
    private val qrScannerCameraClosedBR = QRScannerCameraClosedBR()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (!BuildConfig.DEBUG) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
        }

        yubikit = YubiKitManager(this)

        setupYubiKeyDiscovery()
        setupYubiKitLogger()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    private fun setupYubiKeyDiscovery() {
        viewModel.handleYubiKey.observe(this) {
            if (it) {
                Log.d(TAG, "Starting usb discovery")
                yubikit.startUsbDiscovery(UsbConfiguration()) { device ->
                    viewModel.yubiKeyDevice.postValue(device)
                    device.setOnClosed { viewModel.yubiKeyDevice.postValue(null) }
                }
                hasNfc = startNfcDiscovery()
            } else {
                stopNfcDiscovery()
                yubikit.stopUsbDiscovery()
                Log.d(TAG, "Stopped usb discovery")
            }
        }
    }

    fun startNfcDiscovery(): Boolean =
        try {
            Log.d(TAG, "Starting nfc discovery")
            yubikit.startNfcDiscovery(nfcConfiguration, this) { device ->
                viewModel.yubiKeyDevice.apply {
                    lifecycleScope.launch(Dispatchers.Main) {
                        value = device
                        postValue(null)
                    }
                }
            }
            true
        } catch (e: NfcNotAvailable) {
            false
        }

    private fun stopNfcDiscovery() {
        if (hasNfc) {
            yubikit.stopNfcDiscovery(this)
            Log.d(TAG, "Stopped nfc discovery")
        }
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
        super.onPause()
    }

    override fun onResume() {
        super.onResume()

        try {
            if (intent.getBooleanExtra(EXTRA_OPENED_THROUGH_NFC, false)) {
                // make nfc available to yubikit
                NfcAdapter.getDefaultAdapter(this).disableReaderMode(this)
                setupYubiKeyDiscovery()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failure when resuming YubiKey discovery", e.stackTraceToString())
        }

        startNfcDiscovery()
    }

    private lateinit var appContext: AppContext
    private lateinit var oathManager: OathManager
    private lateinit var dialogManager: DialogManager
    private lateinit var appPreferences: AppPreferences
    private lateinit var flutterLog: FlutterLog

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        flutterLog = FlutterLog(messenger)
        appContext = AppContext(messenger, this.lifecycleScope)
        dialogManager = DialogManager(messenger, this.lifecycleScope)
        appPreferences = AppPreferences(this)

        oathManager = OathManager(this, messenger, appContext, viewModel, dialogManager, appPreferences)
    }

    companion object {
        const val TAG = "MainActivity"
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
}
