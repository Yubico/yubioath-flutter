package com.yubico.authenticator.flutter_plugins.qrscanner_zxing

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

class PermissionsResultRegistrar {

    private var permissionsResultListener: PluginRegistry.RequestPermissionsResultListener? = null

    fun setListener(listener: PluginRegistry.RequestPermissionsResultListener?) {
        permissionsResultListener = listener
    }

    fun onResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        return permissionsResultListener?.onRequestPermissionsResult(
            requestCode,
            permissions,
            grantResults
        ) ?: false
    }
}

/** QRScannerZxingPlugin */
class QRScannerZxingPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

    private val registrar = PermissionsResultRegistrar()
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "qrscanner_zxing")
        channel.setMethodCallHandler(this)

        binding.platformViewRegistry
            .registerViewFactory(
                "qrScannerNativeView",
                QRScannerViewFactory(binding.binaryMessenger, registrar)
            )
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {

    }

    override fun onDetachedFromActivity() {
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        return registrar.onResult(requestCode, permissions, grantResults)
    }
}
