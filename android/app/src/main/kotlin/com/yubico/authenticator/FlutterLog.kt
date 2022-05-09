package com.yubico.authenticator

import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class FlutterLog(messenger: BinaryMessenger) {

    private enum class LogLevel(val value: Int) {
        TRAFFIC(500),
        DEBUG(700),
        INFO(800),
        WARNING(900),
        ERROR(1000);

        companion object {
            fun fromInt(value: Int?) = values().firstOrNull { it.value == value }
        }
    }

    private var _channel = MethodChannel(messenger, "android.log.redirect")
    private var _level = LogLevel.INFO

    companion object {

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
                    val error = call.argument<String?>("error")
                    val loggerName = call.argument<String>("loggerName")
                    val level = LogLevel.fromInt(call.argument<Int>("level"))

                    if (level != null && loggerName != null && message != null) {
                        log(level, loggerName, message, error)
                        result.success(null)
                    } else {
                        result.error("-1", "Invalid log parameters", null)
                    }
                }
                "setLevel" -> {
                    _level = LogLevel.fromInt(call.argument<Int>("level")) ?: LogLevel.INFO
                }
            }


        }
    }

    private fun log(level: LogLevel, loggerName: String, message: String, error: String?) {

        if (level < _level) {
            return
        }

        when (level) {
            LogLevel.TRAFFIC -> Log.v(loggerName, message)
            LogLevel.DEBUG -> Log.d(loggerName, message)
            LogLevel.INFO -> Log.i(loggerName, message)
            LogLevel.WARNING -> Log.w(loggerName, message)
            LogLevel.ERROR -> Log.e(loggerName, message)
        }

        error?.let {
            Log.e(loggerName, error)
        }
    }
}