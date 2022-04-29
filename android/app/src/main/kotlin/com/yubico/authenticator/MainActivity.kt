package com.yubico.authenticator

import android.os.Bundle
import androidx.activity.viewModels
import androidx.lifecycle.lifecycleScope
import com.yubico.authenticator.api.AppApiImpl
import com.yubico.authenticator.api.HDialogApiImpl
import com.yubico.authenticator.oath.OathApiImpl
import com.yubico.authenticator.api.Pigeon
import com.yubico.yubikit.android.YubiKitManager
import com.yubico.yubikit.android.transport.nfc.NfcConfiguration
import com.yubico.yubikit.android.transport.nfc.NfcNotAvailable
import com.yubico.yubikit.android.transport.usb.UsbConfiguration
import com.yubico.yubikit.core.Logger
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
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

        viewModel.yubiKeyDevice.observe(this) { yubikey ->

            lifecycleScope.launch(Dispatchers.Main) {
                withContext(Dispatchers.Main) {
                    if (yubikey != null) {
                        Logger.d("A device was connected: $yubikey")
                        viewModel.yubikeyAttached(yubikey)

                    } else {
                        Logger.d("A device was disconnected")
                        viewModel.yubikeyDetached()
                    }
                }
            }
        }
    }



    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        viewModel.setFOathApi(Pigeon.FOathApi(messenger))
        viewModel.setFManagementApi(Pigeon.FManagementApi(messenger))
        viewModel.setFDialogApi(Pigeon.FDialogApi(messenger))
        Pigeon.OathApi.setup(messenger, OathApiImpl(viewModel))
        Pigeon.AppApi.setup(messenger, AppApiImpl(viewModel))
        Pigeon.HDialogApi.setup(messenger, HDialogApiImpl(viewModel))


        // simple logger for yubikit
        Logger.setLogger(object : Logger() {
            init {
                FlutterLog.create(messenger, this@MainActivity)
            }

            override fun logDebug(message: String) {
                FlutterLog.d(message)
            }

            override fun logError(message: String, throwable: Throwable) {
                FlutterLog.e(message, throwable.message ?: throwable.toString())
            }
        })

    }

}
