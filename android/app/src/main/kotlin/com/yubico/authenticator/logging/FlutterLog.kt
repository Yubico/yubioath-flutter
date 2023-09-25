/*
 * Copyright (C) 2022-2023 Yubico.
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

package com.yubico.authenticator.logging

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.slf4j.Logger
import org.slf4j.LoggerFactory

class FlutterLog(messenger: BinaryMessenger) {
    private var channel = MethodChannel(messenger, "android.log.redirect")

    private val bufferAppender =
        (LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME) as ch.qos.logback.classic.Logger)
            .getAppender("buffer") as BufferAppender

    init {

        channel.setMethodCallHandler { call, result ->

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
                        Log.setLevel(requestedLogLevel)
                    } else {
                        loggerError("Invalid log level requested: $levelArgValue")
                    }
                    result.success(null)
                }
                "getLogs" -> {
                    result.success(bufferAppender.getLogBuffer())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun logLevelFromArgument(argValue: String?): Log.LogLevel? =
        Log.LogLevel.values().firstOrNull { it.name == argValue?.uppercase() }

    private fun loggerError(message: String) {
        log(Log.LogLevel.ERROR,"FlutterLog", message, null)
    }

    private fun log(level: Log.LogLevel, loggerName: String, message: String, error: String?) {
        Log.log(level, loggerName, message, error)
    }
}