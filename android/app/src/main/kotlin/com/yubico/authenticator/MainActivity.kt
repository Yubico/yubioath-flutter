/*
 * Copyright (C) 2022-2024 Yubico.
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
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.nfc.NfcAdapter
import android.nfc.NfcAdapter.STATE_ON
import android.nfc.NfcAdapter.STATE_TURNING_OFF
import android.nfc.Tag
import android.os.Build
import android.os.Bundle
import android.provider.Settings.ACTION_NFC_SETTINGS
import android.view.WindowManager
import androidx.activity.viewModels
import androidx.core.content.ContextCompat
import androidx.core.view.WindowCompat
import androidx.lifecycle.lifecycleScope
import com.google.android.material.color.DynamicColors
import com.yubico.authenticator.device.DeviceManager
import com.yubico.authenticator.fido.FidoManager
import com.yubico.authenticator.fido.FidoViewModel
import com.yubico.authenticator.logging.FlutterLog
import com.yubico.authenticator.management.ManagementHandler
import com.yubico.authenticator.oath.AppLinkMethodChannel
import com.yubico.authenticator.oath.OathManager
import com.yubico.authenticator.oath.OathViewModel
import com.yubico.authenticator.yubikit.DeviceInfoHelper.Companion.getDeviceInfo
import com.yubico.authenticator.yubikit.withConnection
import com.yubico.yubikit.android.YubiKitManager
import com.yubico.yubikit.android.transport.nfc.NfcConfiguration
import com.yubico.yubikit.android.transport.nfc.NfcNotAvailable
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.android.transport.usb.UsbConfiguration
import com.yubico.yubikit.core.Transport
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.smartcard.scp.Scp11KeyParams
import com.yubico.yubikit.core.smartcard.scp.ScpKeyParams
import com.yubico.yubikit.core.smartcard.scp.ScpKid
import com.yubico.yubikit.core.smartcard.scp.SecurityDomainSession
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.launch
import org.json.JSONObject
import org.slf4j.LoggerFactory
import java.io.Closeable
import java.util.concurrent.Executors

class MainActivity : FlutterFragmentActivity() {
    private val viewModel: MainViewModel by viewModels()
    private val oathViewModel: OathViewModel by viewModels()
    private val fidoViewModel: FidoViewModel by viewModels()

    private val nfcConfiguration = NfcConfiguration().timeout(2000)

    private var hasNfc: Boolean = false

    private lateinit var yubikit: YubiKitManager

    private var preserveConnectionOnPause: Boolean = false

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
                this
            ) { nfcYubiKeyDevice ->
                if (!deviceManager.isUsbKeyConnected()) {
                    launchProcessYubiKey(nfcYubiKeyDevice)
                }
            }

            hasNfc = true
        } catch (_: NfcNotAvailable) {
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
            launchProcessYubiKey(device)
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

        contextManager?.onPause()

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
                        processYubiKey(device)
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

            val usbManager = getSystemService(USB_SERVICE) as UsbManager
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

    private suspend fun processYubiKey(device: YubiKeyDevice) {
        val deviceInfo = getDeviceInfo(device)
        deviceManager.setDeviceInfo(deviceInfo)

        if (deviceInfo == null) {
            return
        }

        // If NFC and FIPS check for SCP11b key
        if (device.transport == Transport.NFC && deviceInfo.fipsCapable != 0) {
            logger.debug("Checking for usable SCP11b key...")
            deviceManager.scpKeyParams =
                device.withConnection<SmartCardConnection, ScpKeyParams?> { connection ->
                    val scp = SecurityDomainSession(connection)
                    val keyRef = scp.keyInformation.keys.firstOrNull { it.kid == ScpKid.SCP11b }
                    keyRef?.let {
                        val certs = scp.getCertificateBundle(it)
                        if (certs.isNotEmpty()) Scp11KeyParams(
                            keyRef,
                            certs[certs.size - 1].publicKey
                        ) else null
                    }?.also {
                        logger.debug("Found SCP11b key: {}", keyRef)
                    }
                }
        }

        val supportedContexts = DeviceManager.getSupportedContexts(deviceInfo)
        logger.debug("Connected key supports: {}", supportedContexts)
        if (!supportedContexts.contains(viewModel.appContext.value)) {
            val preferredContext = DeviceManager.getPreferredContext(supportedContexts)
            logger.debug(
                "Current context ({}) is not supported by the key. Using preferred context {}",
                viewModel.appContext.value,
                preferredContext
            )
            switchContext(preferredContext)
        }

        if (contextManager == null && supportedContexts.isNotEmpty()) {
            switchContext(DeviceManager.getPreferredContext(supportedContexts))
        }

        contextManager?.let {
            try {
                it.processYubiKey(device)
            } catch (e: Throwable) {
                logger.error("Error processing YubiKey in AppContextManager", e)
            }
        }
    }

    private fun launchProcessYubiKey(device: YubiKeyDevice) {
        lifecycleScope.launch {
            processYubiKey(device)
        }
    }

    private var contextManager: AppContextManager? = null
    private lateinit var deviceManager: DeviceManager
    private lateinit var appContext: AppContext
    private lateinit var dialogManager: DialogManager
    private lateinit var appPreferences: AppPreferences
    private lateinit var flutterLog: FlutterLog
    private lateinit var flutterStreams: List<Closeable>
    private lateinit var appMethodChannel: AppMethodChannel
    private lateinit var appLinkMethodChannel: AppLinkMethodChannel
    private lateinit var messenger: BinaryMessenger
    private lateinit var managementHandler: ManagementHandler

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        messenger = flutterEngine.dartExecutor.binaryMessenger
        flutterLog = FlutterLog(messenger)
        deviceManager = DeviceManager(this, viewModel)
        appContext = AppContext(messenger, this.lifecycleScope, viewModel)
        dialogManager = DialogManager(messenger, this.lifecycleScope)
        appPreferences = AppPreferences(this)
        appMethodChannel = AppMethodChannel(messenger)
        appLinkMethodChannel = AppLinkMethodChannel(messenger)
        managementHandler = ManagementHandler(messenger, deviceManager, dialogManager)

        flutterStreams = listOf(
            viewModel.deviceInfo.streamTo(this, messenger, "android.devices.deviceInfo"),
            oathViewModel.sessionState.streamTo(this, messenger, "android.oath.sessionState"),
            oathViewModel.credentials.streamTo(this, messenger, "android.oath.credentials"),
            fidoViewModel.sessionState.streamTo(this, messenger, "android.fido.sessionState"),
            fidoViewModel.credentials.streamTo(this, messenger, "android.fido.credentials"),
            fidoViewModel.fingerprints.streamTo(this, messenger, "android.fido.fingerprints"),
            fidoViewModel.resetState.streamTo(this, messenger, "android.fido.reset"),
            fidoViewModel.registerFingerprint.streamTo(this, messenger, "android.fido.registerFp"),
        )

        viewModel.appContext.observe(this) {
            switchContext(it)
            viewModel.connectedYubiKey.value?.let(::launchProcessYubiKey)
        }
    }

    private fun switchContext(appContext: OperationContext) {
        // TODO: refactor this when more OperationContext are handled
        // only recreate the contextManager object if it cannot be reused
        if (appContext == OperationContext.Home ||
            (appContext == OperationContext.Oath && contextManager is OathManager) ||
            (appContext in listOf(
                OperationContext.FidoPasskeys,
                OperationContext.FidoFingerprints
            ) && contextManager is FidoManager)
        ) {
            // no need to dispose this context
        } else {
            contextManager?.dispose()
            contextManager = null
        }

        if (contextManager == null) {
            contextManager = when (appContext) {
                OperationContext.Oath -> OathManager(
                    this,
                    messenger,
                    deviceManager,
                    oathViewModel,
                    dialogManager,
                    appPreferences
                )

                OperationContext.FidoFingerprints,
                OperationContext.FidoPasskeys -> FidoManager(
                    messenger,
                    this,
                    deviceManager,
                    fidoViewModel,
                    viewModel,
                    dialogManager
                )

                else -> null
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        flutterStreams.forEach { it.close() }
        contextManager?.dispose()
        deviceManager.dispose()
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

                    "getPrimaryColor" -> result.success(
                        getPrimaryColor(this@MainActivity)
                    )

                    "getAndroidSdkVersion" -> result.success(
                        Build.VERSION.SDK_INT
                    )

                    "preserveConnectionOnPause" -> {
                        preserveConnectionOnPause = true
                        result.success(
                            true
                        )
                    }

                    "setPrimaryClip" -> {
                        val toClipboard = methodCall.argument<String>("toClipboard")
                        val isSensitive = methodCall.argument<Boolean>("isSensitive")
                        if (toClipboard != null && isSensitive != null) {
                            ClipboardUtil.setPrimaryClip(
                                this@MainActivity,
                                toClipboard,
                                isSensitive
                            )
                        }
                        result.success(true)
                    }

                    "hasCamera" -> {
                        val cameraService =
                            getSystemService(CAMERA_SERVICE) as CameraManager
                        result.success(
                            cameraService.cameraIdList.any {
                                cameraService.getCameraCharacteristics(it)
                                    .get(CameraCharacteristics.LENS_FACING) == CameraCharacteristics.LENS_FACING_BACK
                            }
                        )
                    }

                    "hasNfc" -> result.success(
                        packageManager.hasSystemFeature(PackageManager.FEATURE_NFC)
                    )

                    "isNfcEnabled" -> {
                        val nfcAdapter = NfcAdapter.getDefaultAdapter(this@MainActivity)

                        result.success(
                            nfcAdapter != null && nfcAdapter.isEnabled
                        )
                    }

                    "openNfcSettings" -> {
                        startActivity(Intent(ACTION_NFC_SETTINGS))
                        result.success(true)
                    }

                    else -> logger.warn("Unknown app method: {}", methodCall.method)
                }
            }
        }

        fun nfcAdapterStateChanged(value: Boolean) {
            methodChannel.invokeMethod(
                "nfcAdapterStateChanged",
                JSONObject(mapOf("nfcEnabled" to value)).toString()
            )
        }
    }

    private fun allowScreenshots(value: Boolean): Boolean {
        // Note that FLAG_SECURE is the inverse of allowScreenshots
        if (value) {
            logger.debug("Clearing FLAG_SECURE (allow screenshots)")
            window.clearFlags(FLAG_SECURE)
        } else {
            logger.debug("Setting FLAG_SECURE (disallow screenshots)")
            window.setFlags(FLAG_SECURE, FLAG_SECURE)
        }

        return FLAG_SECURE != (window.attributes.flags and FLAG_SECURE)
    }

    private fun getPrimaryColor(context: Context): Int? {
        if (DynamicColors.isDynamicColorAvailable()) {
            val dynamicColorContext = DynamicColors.wrapContextIfAvailable(
                context,
                com.google.android.material.R.style.ThemeOverlay_Material3_DynamicColors_DayNight
            )

            val typedArray = dynamicColorContext.obtainStyledAttributes(
                intArrayOf(
                    android.R.attr.colorPrimary,
                )
            )
            try {
                return if (typedArray.hasValue(0))
                    typedArray.getColor(0, 0)
                else
                    null
            } finally {
                typedArray.recycle()
            }
        }
        return null
    }

    @SuppressLint("SourceLockedOrientationActivity")
    private fun forcePortraitOrientation() {
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
    }

    private fun allowAnyOrientation() {
        requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
    }

    private fun isPortraitOnly() = resources.getBoolean(R.bool.portrait_only)
}
