package com.yubico.authenticator.logging

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class FlutterLog(messenger: BinaryMessenger) {

    private var _channel = MethodChannel(messenger, "android.log.redirect")

    init {
        _channel.setMethodCallHandler { call, result ->

            when (call.method) {
                "log" -> {
                    val message = call.argument<String>("message")
                    val error = call.argument<String>("error")
                    val loggerName = call.argument<String>("loggerName")
                    val levelValue = call.argument<String>("level")
                    val level = logLevelFromArgument(levelValue)

                    if (level == null) {
                        loggerError("Invalid level for message from [$loggerName]: $levelValue")
                    } else if (loggerName != null && message != null) {
                        Log.log(level, loggerName, message, error)
                        result.success(null)
                    } else {
                        result.error("-1", "Invalid log parameters", null)
                    }
                }
                "setLevel" -> {
                    val levelArgValue = call.argument<String>("level")
                    val requestedLogLevel = logLevelFromArgument(levelArgValue)
                    if (requestedLogLevel != null) {
                        Log.setLevel(requestedLogLevel)
                    } else {
                        loggerError("Invalid log level requested: $levelArgValue")
                    }
                }
            }
        }
    }

    private fun logLevelFromArgument(argValue: String?): Log.LogLevel? =
        Log.LogLevel.values().firstOrNull { it.name == argValue?.uppercase() }

    private fun loggerError(message: String) {
        Log.e("FlutterLog", message, null)
    }
}