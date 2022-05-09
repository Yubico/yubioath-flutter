package com.yubico.authenticator

import android.os.Bundle
import androidx.activity.viewModels
import androidx.lifecycle.lifecycleScope
import com.yubico.authenticator.oath.OathManager
import com.yubico.yubikit.android.YubiKitManager
import com.yubico.yubikit.android.transport.nfc.NfcConfiguration
import com.yubico.yubikit.android.transport.nfc.NfcNotAvailable
import com.yubico.yubikit.android.transport.usb.UsbConfiguration
import com.yubico.yubikit.core.Logger
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
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

        yubikit = YubiKitManager(this)

        viewModel.handleYubiKey.observe(this) {
            if (it) {
                yubikit.startUsbDiscovery(UsbConfiguration()) { device ->
                    viewModel.yubiKeyDevice.postValue(device)
                    device.setOnClosed { viewModel.yubiKeyDevice.postValue(null) }
                }
                hasNfc = try {
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
            } else {
                yubikit.stopNfcDiscovery(this)
                yubikit.stopUsbDiscovery()
            }
        }
    }

    private fun initializeLogger(messenger: BinaryMessenger) {
        Logger.setLogger(object : Logger() {
            private val TAG = "yubikit"

            init {
                FlutterLog.create(messenger)
            }

            override fun logDebug(message: String) {
                // redirect yubikit debug logs to flutter traffic
                FlutterLog.t(TAG, message)
            }

            override fun logError(message: String, throwable: Throwable) {
                FlutterLog.e(TAG, message, throwable.message ?: throwable.toString())
            }
        })
    }

    private lateinit var appContext: AppContext
    private lateinit var oathManager: OathManager
    private lateinit var dialogManager: DialogManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        appContext = AppContext(messenger)
        dialogManager = DialogManager(messenger, this.lifecycleScope)

        oathManager = OathManager(this, messenger, appContext, viewModel, dialogManager)

        initializeLogger(messenger)

    }

}
