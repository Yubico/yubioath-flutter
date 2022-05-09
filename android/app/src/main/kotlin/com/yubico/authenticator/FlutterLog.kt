package com.yubico.authenticator

import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class FlutterLog(messenger: BinaryMessenger) {

    private enum class LogLevel {
        TRAFFIC,
        DEBUG,
        INFO,
        WARNING,
        ERROR
    }

    private var _channel = MethodChannel(messenger, "android.log.redirect")
    private var _level = LogLevel.INFO

    companion object {
        private const val TAG = "yubico-authenticator"

        private lateinit var instance: FlutterLog

        fun create(messenger: BinaryMessenger) {
            instance = FlutterLog(messenger)
        }

        @Suppress("unused")
        fun t(tag: String, message: String, error: String? = null) {
            instance.log(LogLevel.TRAFFIC, tag, message, error)
        }

        @Suppress("unused")
        fun d(tag: String, message: String, error: String? = null) {
            instance.log(LogLevel.DEBUG, tag, message, error)
        }

        @Suppress("unused")
        fun i(tag: String, message: String, error: String? = null) {
            instance.log(LogLevel.INFO, tag, message, error)
        }

        @Suppress("unused")
        fun w(tag: String, message: String, error: String? = null) {
            instance.log(LogLevel.WARNING, tag, message, error)
        }

        @Suppress("unused")
        fun e(tag: String, message: String, error: String? = null) {
            instance.log(LogLevel.ERROR, tag, message, error)
        }
    }

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
                        log(level, loggerName, message, error)
                        result.success(null)
                    } else {
                        result.error("-1", "Invalid log parameters", null)
                    }
                }
                "setLevel" -> {
                    val levelArgValue = call.argument<String>("level")
                    val requestedLogLevel = logLevelFromArgument(levelArgValue)
                    if (requestedLogLevel != null) {
                        _level = requestedLogLevel
                    } else {
                        loggerError("Invalid log level requested: $levelArgValue")
                    }
                }
            }
        }
    }

    private fun logLevelFromArgument(argValue: String?): LogLevel? =
        LogLevel.values().firstOrNull { it.name == argValue?.uppercase() }

    private fun loggerError(message: String) {
        log(LogLevel.ERROR, "FlutterLog", message, null)
    }

    private fun log(level: LogLevel, loggerName: String, message: String, error: String?) {
        if (level < _level) {
            return
        }

        val logMessage = "[$loggerName] ${level.name}: $message"

        when (level) {
            LogLevel.TRAFFIC -> Log.v(TAG, logMessage)
            LogLevel.DEBUG -> Log.d(TAG, logMessage)
            LogLevel.INFO -> Log.i(TAG, logMessage)
            LogLevel.WARNING -> Log.w(TAG, logMessage)
            LogLevel.ERROR -> Log.e(TAG, logMessage)
        }

        error?.let {
            Log.e(TAG, "[$loggerName] ${level.name}: $error")
        }
    }
}