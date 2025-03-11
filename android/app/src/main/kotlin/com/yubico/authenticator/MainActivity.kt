/*
 * Copyright (C) 2022-2025 Yubico.
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
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
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
import com.yubico.authenticator.OperationContext.Companion.getPreferredContext
import com.yubico.authenticator.OperationContext.Companion.getSupportedContexts
import com.yubico.authenticator.device.DeviceManager
import com.yubico.authenticator.device.noScp11bNfcSupport
import com.yubico.authenticator.fido.FidoManager
import com.yubico.authenticator.fido.FidoViewModel
import com.yubico.authenticator.logging.FlutterLog
import com.yubico.authenticator.management.ManagementManager
import com.yubico.authenticator.oath.AppLinkMethodChannel
import com.yubico.authenticator.oath.OathManager
import com.yubico.authenticator.oath.OathViewModel
import com.yubico.authenticator.yubikit.DeviceInfoHelper.Companion.getDeviceInfo
import com.yubico.authenticator.yubikit.NfcState
import com.yubico.authenticator.yubikit.NfcStateDispatcher
import com.yubico.authenticator.yubikit.NfcStateListener
import com.yubico.authenticator.yubikit.Workarounds
import com.yubico.yubikit.android.YubiKitManager
import com.yubico.yubikit.android.transport.nfc.NfcConfiguration
import com.yubico.yubikit.android.transport.nfc.NfcNotAvailable
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyManager
import com.yubico.yubikit.android.transport.usb.UsbConfiguration
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyManager
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
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject
import org.slf4j.LoggerFactory
import java.io.Closeable
import java.io.IOException
import java.security.NoSuchAlgorithmException
import java.util.concurrent.Executors
import javax.crypto.Mac

class MainActivity : FlutterFragmentActivity() {
    private val viewModel: MainViewModel by viewModels()
    private val oathViewModel: OathViewModel by viewModels()
    private val fidoViewModel: FidoViewModel by viewModels()

    private val nfcConfiguration = NfcConfiguration().timeout(5000)

    private var hasNfc: Boolean = false

    private lateinit var yubikit: YubiKitManager

    private var preserveConnectionOnPause: Boolean = false

    // receives broadcasts when QR Scanner camera is closed
    private val qrScannerCameraClosedBR = QRScannerCameraClosedBR()
    private val nfcAdapterStateChangeBR = NfcAdapterStateChangedBR()
    private val activityUtil = ActivityUtil(this)

    private val logger = LoggerFactory.getLogger(MainActivity::class.java)

    private val nfcStateListener = object : NfcStateListener {

        var appMethodChannel: AppMethodChannel? = null

        override fun onChange(newState: NfcState) {
            appMethodChannel?.let {
                logger.debug("set nfc state to ${newState.name}")
                it.nfcStateChanged(newState)
            } ?: {
                logger.warn("failed set nfc state to ${newState.name} - no method channel")
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (isPortraitOnly()) {
            forcePortraitOrientation()
        }

        WindowCompat.setDecorFitsSystemWindows(window, false)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            window.setHideOverlayWindows(true)
        }
        allowScreenshots(false)

        val nfcManager = if (NfcAdapter.getDefaultAdapter(this) != null) {
            NfcYubiKeyManager(this, NfcStateDispatcher(nfcStateListener))
        } else null

        yubikit = YubiKitManager(UsbYubiKeyManager(this), nfcManager)
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
        if (!Workarounds.handleFidoReclaim(
                deviceManager, device,
                enterReclaimCallback = {
                    appMethodChannel.nfcStateChanged(NfcState.USB_ACTIVITY_ONGOING)
                },
                leaveReclaimCallback = {
                    appMethodChannel.nfcStateChanged(NfcState.USB_ACTIVITY_SUCCESS)
                },
                failureCallback = {
                    appMethodChannel.nfcStateChanged(NfcState.USB_ACTIVITY_FAILURE)
                })
        ) {
            // failure handling reclaim, we cannot use the key
            return
        }
        val deviceInfo = try {
            deviceManager.scpKeyParams = null
            if (device is NfcYubiKeyDevice) {
                appMethodChannel.nfcStateChanged(NfcState.ONGOING)
            }
            getDeviceInfo(device).also {
                deviceManager.scpKeyParams = readScpKeyParams(device, it.fipsCapable)
            }
        } catch (e: Exception) {
            logger.debug("Exception while getting device info and scp keys: ", e)
            contextManager?.onError(e)
            if (device is NfcYubiKeyDevice) {
                appMethodChannel.nfcStateChanged(NfcState.FAILURE)
            }

            // do not clear deviceInfo on IOExceptions,
            // this allows for retries of failed actions
            if (e !is IOException) {
                logger.debug("Resetting device info")
                deviceManager.setDeviceInfo(null)
            }

            return
        }

        // this YubiKey provides SCP11b key but the phone cannot perform AESCMAC
        if (deviceManager.scpKeyParams != null && !supportsScp11b) {
            deviceManager.setDeviceInfo(noScp11bNfcSupport)
            return
        }

        deviceManager.setDeviceInfo(deviceInfo)

        contextManagers.values.firstOrNull(AppContextManager::hasPending)?.let {
            // this context is waiting for the next action,
            // we have to switch to it if it is not active
            if (contextManager != it) {
                contextManager?.deactivate()
                it.activate()
            }

            try {
                logger.debug("Processing pending action in context {}", it)
                if (it.processYubiKey(device)) {
                    appMethodChannel.nfcStateChanged(NfcState.SUCCESS)
                }
                if (device is NfcYubiKeyDevice) {
                    device.remove {
                        appMethodChannel.nfcStateChanged(NfcState.IDLE)
                    }
                }
            } catch (e: Exception) {
                logger.debug("Caught Exception during YubiKey processing: ", e)
                appMethodChannel.nfcStateChanged(NfcState.FAILURE)
            }

            if (contextManager != it) {
                it.deactivate()
                contextManager?.activate()
            }
            logger.debug("Finished execution of pending action in {} context", it)
            return
        }

        // there was no pending action, switch context manager if needed
        val supportedContexts = deviceInfo.getSupportedContexts()
        var switchedContextManager = false
        if (!supportedContexts.contains(viewModel.appContext.value)) {
            val preferredContext = getPreferredContext(supportedContexts)
            logger.debug(
                "Current context ({}) is not supported by the key. Using preferred context {}",
                viewModel.appContext.value,
                preferredContext
            )
            switchedContextManager = switchContextManager(preferredContext)
            if (switchedContextManager) {
                appMethodChannel.appContextChanged(preferredContext)
            }
        }

        contextManager?.let {
            try {
                val requestHandled = it.processYubiKey(device)
                if (requestHandled) {
                    appMethodChannel.nfcStateChanged(NfcState.SUCCESS)
                }
                if (!switchedContextManager && device is NfcYubiKeyDevice) {
                    device.remove {
                        appMethodChannel.nfcStateChanged(NfcState.IDLE)
                    }
                }
            } catch (e: Exception) {
                logger.debug("Caught Exception during YubiKey processing: ", e)
                appMethodChannel.nfcStateChanged(NfcState.FAILURE)
            }
        }

    }

    private fun launchProcessYubiKey(device: YubiKeyDevice) {
        lifecycleScope.launch {
            processYubiKey(device)
        }
    }

    private var contextManager: AppContextManager? = null
    private lateinit var contextManagers: Map<OperationContext, AppContextManager>
    private lateinit var deviceManager: DeviceManager
    private lateinit var appContext: AppContext
    private lateinit var nfcOverlayManager: NfcOverlayManager
    private lateinit var appPreferences: AppPreferences
    private lateinit var flutterLog: FlutterLog
    private lateinit var flutterStreams: List<Closeable>
    private lateinit var appMethodChannel: AppMethodChannel
    private lateinit var appLinkMethodChannel: AppLinkMethodChannel
    private lateinit var messenger: BinaryMessenger

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        messenger = flutterEngine.dartExecutor.binaryMessenger
        flutterLog = FlutterLog(messenger)
        appMethodChannel = AppMethodChannel(messenger)
        nfcOverlayManager = NfcOverlayManager(messenger, this.lifecycleScope)
        deviceManager = DeviceManager(this, viewModel, appMethodChannel, nfcOverlayManager)
        appContext = AppContext(messenger, this.lifecycleScope, viewModel)

        appPreferences = AppPreferences(this)
        appLinkMethodChannel = AppLinkMethodChannel(messenger)

        nfcStateListener.appMethodChannel = appMethodChannel

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
            if (it != OperationContext.Invalid) {
                switchContextManager(it)
                viewModel.connectedYubiKey.value?.let(::launchProcessYubiKey)
            }
        }

        val homeContextManager = HomeContextManager(deviceManager)
        val oathContextManager = OathManager(
            messenger,
            deviceManager,
            this,
            oathViewModel,
            nfcOverlayManager,
            appPreferences
        )
        val fidoContextManager = FidoManager(
            messenger,
            deviceManager,
            this,
            appMethodChannel,
            nfcOverlayManager,
            fidoViewModel,
            viewModel
        )
        val managementContextManager = ManagementManager(messenger, deviceManager)

        contextManagers = mapOf(
            OperationContext.Home to homeContextManager,
            OperationContext.Oath to oathContextManager,
            OperationContext.FidoPasskeys to fidoContextManager,
            OperationContext.FidoFingerprints to fidoContextManager,
            OperationContext.Management to managementContextManager,
            // currently not supported
            OperationContext.FidoU2f to homeContextManager,
            OperationContext.HsmAuth to homeContextManager,
            OperationContext.OpenPgp to homeContextManager,
            OperationContext.YubiOtp to homeContextManager,
        )
        contextManager = contextManagers[OperationContext.Home]
    }

    private fun switchContextManager(appContext: OperationContext): Boolean {
        contextManager?.let {
            if (it.supports(appContext)) {
                logger.debug(
                    "ContextManager ({}) does not need switching to {}.",
                    contextManager,
                    appContext
                )
                return false
            }
        }
        contextManager?.deactivate()
        contextManager = contextManagers[appContext]
        contextManager?.activate()
        return true
    }

    private fun readScpKeyParams(device: YubiKeyDevice, fipsCapable: Int): ScpKeyParams? =
        if (device.transport == Transport.NFC && fipsCapable != 0) {
            logger.debug("Checking for usable SCP11b key...")
            try {
                device.openConnection(SmartCardConnection::class.java).use { connection ->
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
            } catch (e: Exception) {
                logger.error("Exception when reading SCP key information: ", e)
                // we throw IO exception to unify handling failures as we don't want
                // th clear device info
                throw IOException("Failure getting SCP keys")
            }
        } else
            null


    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        nfcStateListener.appMethodChannel = null
        flutterStreams.forEach { it.close() }
        contextManagers.values.forEach(AppContextManager::dispose)
        deviceManager.dispose()
        super.cleanUpFlutterEngine(flutterEngine)
    }

    companion object {
        const val YUBICO_VENDOR_ID = 4176
        const val FLAG_SECURE = WindowManager.LayoutParams.FLAG_SECURE
        val supportsScp11b = try {
            Mac.getInstance("AESCMAC")
            true
        } catch (_: NoSuchAlgorithmException) {
            false
        }
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
                JSONObject(mapOf("enabled" to value)).toString()
            )
        }

        fun nfcStateChanged(activityState: NfcState) {
            lifecycleScope.launch(Dispatchers.Main) {
                methodChannel.invokeMethod(
                    "nfcStateChanged",
                    JSONObject(mapOf("state" to activityState.value)).toString()
                )
            }
        }

        fun appContextChanged(appContext: OperationContext) {
            lifecycleScope.launch(Dispatchers.Main) {
                methodChannel.invokeMethod(
                    "appContextChanged",
                    JSONObject(mapOf("appContext" to appContext.value)).toString()
                )
            }
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
