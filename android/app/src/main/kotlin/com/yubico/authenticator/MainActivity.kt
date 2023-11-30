/*
 * Copyright (C) 2022-2023 Yubico.
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

package com.yubico.authenticator

import android.annotation.SuppressLint
import android.content.*
import android.content.SharedPreferences.OnSharedPreferenceChangeListener
import android.content.pm.ActivityInfo
import android.content.res.Configuration
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.nfc.NfcAdapter
import android.nfc.NfcAdapter.STATE_ON
import android.nfc.NfcAdapter.STATE_TURNING_OFF
import android.nfc.Tag
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.viewModels
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import androidx.lifecycle.lifecycleScope
import com.yubico.authenticator.app.AppMethodChannel
import com.yubico.authenticator.app.allowScreenshots
import com.yubico.authenticator.logging.FlutterLog
import com.yubico.authenticator.oath.AppLinkMethodChannel
import com.yubico.authenticator.oath.OathManager
import com.yubico.authenticator.oath.OathViewModel
import com.yubico.yubikit.android.YubiKitManager
import com.yubico.yubikit.android.transport.nfc.NfcConfiguration
import com.yubico.yubikit.android.transport.nfc.NfcNotAvailable
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.android.transport.usb.UsbConfiguration
import com.yubico.yubikit.core.YubiKeyDevice
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.launch
import org.slf4j.LoggerFactory
import java.io.Closeable
import java.util.concurrent.Executors

class MainActivity : FlutterFragmentActivity() {
    private val viewModel: MainViewModel by viewModels()
    private val oathViewModel: OathViewModel by viewModels()

    private val nfcConfiguration = NfcConfiguration()

    private var hasNfc: Boolean = false

    private lateinit var yubikit: YubiKitManager

    var preserveConnectionOnPause: Boolean = false

    // receives broadcasts when QR Scanner camera is closed
    private val qrScannerCameraClosedBR = QRScannerCameraClosedBR()
    private val nfcAdapterStateChangeBR = NfcAdapterStateChangedBR()
    private val activityUtil = ActivityUtil(this)

    private val logger = LoggerFactory.getLogger(MainActivity::class.java)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (isPortraitOnly()) {
            forcePortraitOrientation()
        }

        WindowCompat.setDecorFitsSystemWindows(window, false)

        allowScreenshots(false)

        yubikit = YubiKitManager(this)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    private fun startNfcDiscovery() =
        try {
            logger.debug("Starting nfc discovery")
            yubikit.startNfcDiscovery(
                nfcConfiguration.disableNfcDiscoverySound(appPreferences.silenceNfcSounds),
                this,
                ::processYubiKey
            )
            hasNfc = true
        } catch (e: NfcNotAvailable) {
            hasNfc = false
        }

    private fun stopNfcDiscovery() {
        if (hasNfc) {
            yubikit.stopNfcDiscovery(this)
            logger.debug("Stopped nfc discovery")
        }
    }

    private fun startUsbDiscovery() {
        logger.debug("Starting usb discovery")
        val usbConfiguration = UsbConfiguration().handlePermissions(true)
        yubikit.startUsbDiscovery(usbConfiguration) { device ->
            viewModel.setConnectedYubiKey(device) {
                logger.debug("YubiKey was disconnected, stopping usb discovery")
                stopUsbDiscovery()
            }
            processYubiKey(device)
        }
    }

    private fun stopUsbDiscovery() {
        yubikit.stopUsbDiscovery()
        logger.debug("Stopped usb discovery")
    }

    @SuppressLint("WrongConstant")
    override fun onStart() {
        super.onStart()
        ContextCompat.registerReceiver(
            this,
            qrScannerCameraClosedBR,
            QRScannerCameraClosedBR.intentFilter,
            ContextCompat.RECEIVER_NOT_EXPORTED
        )
        ContextCompat.registerReceiver(
            this,
            nfcAdapterStateChangeBR,
            NfcAdapterStateChangedBR.intentFilter,
            ContextCompat.RECEIVER_EXPORTED
        )
    }

    override fun onStop() {
        super.onStop()
        unregisterReceiver(qrScannerCameraClosedBR)
        unregisterReceiver(nfcAdapterStateChangeBR)
    }

    override fun onPause() {

        appPreferences.unregisterListener(sharedPreferencesListener)

        if (!preserveConnectionOnPause) {
            stopUsbDiscovery()
            stopNfcDiscovery()
        } else {
            logger.debug("Any existing connections are preserved")
        }

        if (!appPreferences.openAppOnUsb) {
            activityUtil.disableSystemUsbDiscovery()
        }

        if (appPreferences.openAppOnNfcTap || appPreferences.copyOtpOnNfcTap) {
            activityUtil.enableAppNfcDiscovery()
        } else {
            activityUtil.disableAppNfcDiscovery()
        }

        super.onPause()
    }

    override fun onResume() {
        super.onResume()

        activityUtil.enableSystemUsbDiscovery()

        if (!preserveConnectionOnPause) {
            // Handle opening through otpauth:// link
            val intentData = intent.data
            if (intentData != null &&
                (intentData.scheme == "otpauth" ||
                        intentData.scheme == "otpauth-migration")
            ) {
                intent.data = null
                appLinkMethodChannel.handleUri(intentData)
            }

            // Handle existing tag when launched from NDEF
            val tag = intent.parcelableExtra<Tag>(NfcAdapter.EXTRA_TAG)
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
                        logger.error("Error processing YubiKey in AppContextManager", e)
                    }
                }
            } else {
                startNfcDiscovery()
            }

            val usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
            if (UsbManager.ACTION_USB_DEVICE_ATTACHED == intent.action) {
                val device = intent.parcelableExtra<UsbDevice>(UsbManager.EXTRA_DEVICE)
                if (device != null) {
                    // start the USB discover only if the user approved the app to use the device
                    if (usbManager.hasPermission(device)) {
                        startUsbDiscovery()
                    }
                }
            } else {
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
        } else {
            logger.debug("Resume with preserved connection")
        }

        appPreferences.registerListener(sharedPreferencesListener)

        preserveConnectionOnPause = false
    }

    override fun onMultiWindowModeChanged(isInMultiWindowMode: Boolean, newConfig: Configuration) {
        super.onMultiWindowModeChanged(isInMultiWindowMode, newConfig)

        if (isPortraitOnly()) {
            when (isInMultiWindowMode) {
                true -> allowAnyOrientation()
                else -> forcePortraitOrientation()
            }
        }
    }

    private fun processYubiKey(device: YubiKeyDevice) {
        contextManager?.let {
            lifecycleScope.launch {
                try {
                    it.processYubiKey(device)
                } catch (e: Throwable) {
                    logger.error("Error processing YubiKey in AppContextManager", e)
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
    private lateinit var appLinkMethodChannel: AppLinkMethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        flutterLog = FlutterLog(messenger)
        appContext = AppContext(messenger, this.lifecycleScope, viewModel)
        dialogManager = DialogManager(messenger, this.lifecycleScope)
        appPreferences = AppPreferences(this)
        appMethodChannel = AppMethodChannel(this, messenger)
        appLinkMethodChannel = AppLinkMethodChannel(messenger)

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
        const val YUBICO_VENDOR_ID = 4176
        const val FLAG_SECURE = WindowManager.LayoutParams.FLAG_SECURE
    }

    /** We observed that some devices (Pixel 2, OnePlus 6) automatically end NFC discovery
     * during the use of device camera when scanning QR codes. To handle NFC events correctly,
     * this receiver restarts the YubiKit NFC discovery when the QR Scanner camera is closed.
     */
    class QRScannerCameraClosedBR : BroadcastReceiver() {

        private val logger = LoggerFactory.getLogger(QRScannerCameraClosedBR::class.java)

        companion object {
            val intentFilter = IntentFilter("com.yubico.authenticator.QRScannerView.CameraClosed")
        }

        override fun onReceive(context: Context?, intent: Intent?) {
            logger.debug("Restarting nfc discovery after camera was closed.")
            (context as? MainActivity)?.startNfcDiscovery()
        }
    }

    private val sharedPreferencesListener = OnSharedPreferenceChangeListener { _, key ->
        if (AppPreferences.PREF_NFC_SILENCE_SOUNDS == key) {
            stopNfcDiscovery()
            startNfcDiscovery()
        }
    }

    class NfcAdapterStateChangedBR : BroadcastReceiver() {

        private val logger = LoggerFactory.getLogger(NfcAdapterStateChangedBR::class.java)

        companion object {
            val intentFilter = IntentFilter("android.nfc.action.ADAPTER_STATE_CHANGED")
        }

        override fun onReceive(context: Context?, intent: Intent?) {
            intent?.let {
                val state = it.getIntExtra("android.nfc.extra.ADAPTER_STATE", 0)
                logger.debug("NfcAdapter state changed to {}", state)
                if (state == STATE_ON || state == STATE_TURNING_OFF) {
                    (context as? MainActivity)?.appMethodChannel?.nfcAdapterStateChanged(state == STATE_ON)
                }
            }

        }
    }

    @SuppressLint("SourceLockedOrientationActivity")
    private fun forcePortraitOrientation() {
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
    }

    private fun allowAnyOrientation() {
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
    }

    private fun isPortraitOnly() = resources.getBoolean(R.bool.portrait_only);
}
