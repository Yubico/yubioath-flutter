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

        private val logLevelFromArgument: (String?) -> LogLevel = { argValue ->
            LogLevel.valueOf(argValue?.uppercase() ?: "INFO")
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
                    val error = call.argument<String?>("error")
                    val loggerName = call.argument<String>("loggerName")
                    val level = logLevelFromArgument(call.argument("level"))

                    if (loggerName != null && message != null) {
                        log(level, loggerName, message, error)
                        result.success(null)
                    } else {
                        result.error("-1", "Invalid log parameters", null)
                    }
                }
                "setLevel" -> {
                    _level = logLevelFromArgument(call.argument("level"))
                }
            }
        }
    }

    private fun log(level: LogLevel, loggerName: String, message: String, error: String?) {

        if (level < _level) {
            return
        }

        val messageWithLoggerName = "[$loggerName] $message"

        when (level) {
            LogLevel.TRAFFIC -> Log.v(TAG, messageWithLoggerName)
            LogLevel.DEBUG -> Log.d(TAG, messageWithLoggerName)
            LogLevel.INFO -> Log.i(TAG, messageWithLoggerName)
            LogLevel.WARNING -> Log.w(TAG, messageWithLoggerName)
            LogLevel.ERROR -> Log.e(TAG, messageWithLoggerName)
        }

        error?.let {
            Log.e(TAG, "[$loggerName] $error")
        }
    }
}