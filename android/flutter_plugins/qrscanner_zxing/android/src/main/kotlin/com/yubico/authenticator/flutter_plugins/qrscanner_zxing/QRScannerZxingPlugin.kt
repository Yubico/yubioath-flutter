/*
 * Copyright (C) 2022 Yubico.
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
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }

            "scanBitmap" -> {
                val bytes = call.argument<ByteArray>("bytes")
                if (bytes != null) {
                    val scanResult = QrCodeScanner.decodeFromBytes(bytes)
                    result.success(scanResult)
                } else {
                    result.error("Failure", "Invalid image", null)
                }
            }

            else -> {
                result.notImplemented()
            }
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
