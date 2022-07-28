package com.yubico.authenticator

import android.os.Bundle
import android.view.WindowManager
import androidx.activity.viewModels
import androidx.lifecycle.lifecycleScope
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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (!BuildConfig.DEBUG) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
        }

        yubikit = YubiKitManager(this)

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

        setupYubiKitLogger()
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

    fun stopNfcDiscovery() {
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

    private lateinit var appContext: AppContext
    private lateinit var oathManager: OathManager
    private lateinit var dialogManager: DialogManager
    private lateinit var flutterLog: FlutterLog
    private lateinit var nfcDiscoveryHelper: NfcDiscoveryHelper

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        flutterLog = FlutterLog(messenger)
        appContext = AppContext(messenger)
        dialogManager = DialogManager(messenger, this.lifecycleScope)
        nfcDiscoveryHelper = NfcDiscoveryHelper(this)

        oathManager = OathManager(this, messenger, appContext, viewModel, dialogManager, nfcDiscoveryHelper)
    }

    companion object {
        const val TAG = "MainActivity"
    }
}
