package com.yubico.authenticator

import androidx.lifecycle.lifecycleScope
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.launch

class FlutterLog(messenger: BinaryMessenger, private val activity: MainActivity) {

    private var _channel = MethodChannel(messenger, "android.log.redirect")

    companion object {
        private lateinit var instance: FlutterLog

        fun create(messenger: BinaryMessenger, activity: MainActivity) {
            instance = FlutterLog(messenger, activity)
        }

        fun t(message: String, error: String? = null) {
            instance.log("t", message, error)
        }

        fun d(message: String, error: String? = null) {
            instance.log("d", message, error)
        }

        fun i(message: String, error: String? = null) {
            instance.log("i", message, error)
        }

        fun w(message: String, error: String? = null) {
            instance.log("w", message, error)
        }

        fun e(message: String, error: String? = null) {
            instance.log("e", message, error)
        }

        fun wtf(message: String, error: String? = null) {
            instance.log("wtf", message, error)
        }

        fun v(message: String, error: String? = null) {
            instance.log("v", message, error)
        }

    }

    private fun log(level: String, message: String, error: String?) {
        val params = mutableMapOf(
            "level" to level,
            "message" to message
        )

        if (error != null) {
            params["error"] = error
        }

        activity.lifecycleScope.launch {
            _channel.invokeMethod("log", params)
        }
    }
}