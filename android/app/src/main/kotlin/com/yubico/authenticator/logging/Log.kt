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

import ch.qos.logback.classic.Level
import com.yubico.authenticator.BuildConfig
import org.slf4j.Logger
import org.slf4j.LoggerFactory

object Log {

    private val logger = LoggerFactory.getLogger("com.yubico.authenticator.Log")

    enum class LogLevel {
        TRAFFIC,
        DEBUG,
        INFO,
        WARNING,
        ERROR
    }

    private var level = if (BuildConfig.DEBUG) {
        LogLevel.DEBUG
    } else {
        LogLevel.INFO
    }

    init {
        setLevel(level)
    }

    fun log(level: LogLevel, loggerName: String, message: String, error: String?) {
        if (level < this.level) {
            return
        }

        val logMessage = (if (error == null)
            "$message [$loggerName]"
        else
            "$message [$loggerName] (err: $error)")

        when (level) {
            LogLevel.TRAFFIC -> logger.trace(logMessage)
            LogLevel.DEBUG -> logger.debug(logMessage)
            LogLevel.INFO -> logger.info(logMessage)
            LogLevel.WARNING -> logger.warn(logMessage)
            LogLevel.ERROR -> logger.error(logMessage)
        }
    }

    fun setLevel(newLevel: LogLevel) {
        level = newLevel

        val root = LoggerFactory.getLogger(Logger.ROOT_LOGGER_NAME) as ch.qos.logback.classic.Logger
        root.level = when (newLevel) {
            LogLevel.TRAFFIC -> Level.TRACE
            LogLevel.DEBUG -> Level.DEBUG
            LogLevel.INFO -> Level.INFO
            LogLevel.WARNING -> Level.WARN
            LogLevel.ERROR -> Level.ERROR
        }
    }
}