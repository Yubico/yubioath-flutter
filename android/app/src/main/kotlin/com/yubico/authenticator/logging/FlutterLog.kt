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

package com.yubico.authenticator.logging

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class FlutterLog(messenger: BinaryMessenger) {
    private val logger = org.slf4j.LoggerFactory.getLogger(FlutterLog::class.java).also {
        (it as Logger).setTag("") // empty tag hack to not log tag/name for this logger
    }
    private var channel = MethodChannel(messenger, "android.log.redirect")

    init {
        channel.setMethodCallHandler { call, result ->

            when (call.method) {
                "log" -> {
                    val message = call.argument<String>("message")
                    val error = call.argument<String>("error")
                    val loggerName = call.argument<String>("loggerName")
                    val flutterLogLevel = call.argument<String>("level")?.uppercase()

                    when (flutterLogLevel) {
                        "TRAFFIC" -> logger.trace(
                            "[{}] {}: {}",
                            loggerName,
                            flutterLogLevel,
                            message
                        )

                        "DEBUG" -> logger.debug("[{}] {}: {}", loggerName, flutterLogLevel, message)
                        "INFO" -> logger.info("[{}] {}: {}", loggerName, flutterLogLevel, message)
                        "WARNING" -> logger.warn(
                            "[{}] {}: {}",
                            loggerName,
                            flutterLogLevel,
                            message
                        )

                        "ERROR" -> logger.error("[{}] {}: {}", loggerName, flutterLogLevel, message)
                        else -> logger.error(
                            "Invalid level for message from [{}]: {}",
                            loggerName,
                            flutterLogLevel
                        )
                    }
                    error?.let {
                        logger.error("[{}] {}(details): {}", loggerName, flutterLogLevel, it)
                    }
                }
                "setLevel" -> {
                    val levelArgValue = call.argument<String>("level")
                    Logger.setLevel(levelArgValue)
                    result.success(null)
                }
                "getLogs" -> {
                    result.success(Logger.getBuffer())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}