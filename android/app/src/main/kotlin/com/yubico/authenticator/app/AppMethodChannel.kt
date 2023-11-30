package com.yubico.authenticator.app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.nfc.NfcAdapter
import android.os.Build
import android.provider.Settings
import com.yubico.authenticator.ClipboardUtil
import com.yubico.authenticator.MainActivity
import com.yubico.authenticator.invoke
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import org.slf4j.LoggerFactory

class AppMethodChannel(activity: Activity, messenger: BinaryMessenger) {

    private val methodChannel = MethodChannel(messenger, "app.methods")
    private val logger = LoggerFactory.getLogger(AppMethodChannel::class.java)

    init {
        methodChannel.setMethodCallHandler { methodCall, result ->
            when (methodCall.method) {
                "allowScreenshots" -> result.success(
                    activity.allowScreenshots(
                        methodCall.arguments as Boolean
                    )
                )

                "getAndroidSdkVersion" -> result.success(
                    Build.VERSION.SDK_INT
                )

                "preserveConnectionOnPause" -> {
                    if (activity is MainActivity) {
                        activity.preserveConnectionOnPause = true
                        result.success(
                            true
                        )
                    }
                }

                "setPrimaryClip" -> {
                    val toClipboard = methodCall.argument<String>("toClipboard")
                    val isSensitive = methodCall.argument<Boolean>("isSensitive")
                    if (toClipboard != null && isSensitive != null) {
                        ClipboardUtil.setPrimaryClip(
                            activity,
                            toClipboard,
                            isSensitive
                        )
                    }
                    result.success(true)
                }

                "hasCamera" -> {
                    val cameraService =
                        activity.getSystemService(Context.CAMERA_SERVICE) as CameraManager
                    result.success(
                        cameraService.cameraIdList.any {
                            cameraService.getCameraCharacteristics(it)
                                .get(CameraCharacteristics.LENS_FACING) == CameraCharacteristics.LENS_FACING_BACK
                        }
                    )
                }

                "hasNfc" -> result.success(
                    activity.packageManager.hasSystemFeature(PackageManager.FEATURE_NFC)
                )

                "isNfcEnabled" -> {
                    val nfcAdapter = NfcAdapter.getDefaultAdapter(activity)

                    result.success(
                        nfcAdapter != null && nfcAdapter.isEnabled
                    )
                }

                "openNfcSettings" -> {
                    activity.startActivity(Intent(Settings.ACTION_NFC_SETTINGS))
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

    suspend fun getString(arbKey: String) =
        methodChannel.invoke(
            "getString",
            JSONObject(mapOf("arbKey" to arbKey)).toString()
        ) as String
}

fun Activity.allowScreenshots(value: Boolean): Boolean {
    // Note that FLAG_SECURE is the inverse of allowScreenshots
    val logger = LoggerFactory.getLogger("Activity.allowScreenshots")
    if (value) {
        logger.debug("Clearing FLAG_SECURE (allow screenshots)")
        window.clearFlags(MainActivity.FLAG_SECURE)
    } else {
        logger.debug("Setting FLAG_SECURE (disallow screenshots)")
        window.setFlags(MainActivity.FLAG_SECURE, MainActivity.FLAG_SECURE)
    }

    return MainActivity.FLAG_SECURE != (window.attributes.flags and MainActivity.FLAG_SECURE)
}