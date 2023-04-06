/*
 * Copyright (C) 2023 Yubico.
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

import android.util.Log
import com.yubico.authenticator.BuildConfig
import org.slf4j.Marker
import org.slf4j.event.Level
import org.slf4j.helpers.AbstractLogger
import org.slf4j.helpers.MessageFormatter

/**
 * Implementation of [org.slf4j.Logger].
 *
 *
 * For level mapping see [...](https://source.android.com/docs/core/tests/debug/understanding-logging)
 */
class Logger(name: String) : AbstractLogger() {
    private var tag: String? = null

    init {
        this.name = name
    }

    override fun isTraceEnabled(): Boolean {
        return isEnabled(Level.TRACE)
    }

    override fun isTraceEnabled(marker: Marker): Boolean {
        return isTraceEnabled
    }

    override fun isDebugEnabled(): Boolean {
        return isEnabled(Level.DEBUG)
    }

    override fun isDebugEnabled(marker: Marker): Boolean {
        return isDebugEnabled
    }

    override fun isInfoEnabled(): Boolean {
        return isEnabled(Level.INFO)
    }

    override fun isInfoEnabled(marker: Marker): Boolean {
        return isInfoEnabled
    }

    override fun isWarnEnabled(): Boolean {
        return isEnabled(Level.WARN)
    }

    override fun isWarnEnabled(marker: Marker): Boolean {
        return isWarnEnabled
    }

    override fun isErrorEnabled(): Boolean {
        return isEnabled(Level.ERROR)
    }

    override fun isErrorEnabled(marker: Marker): Boolean {
        return isErrorEnabled
    }

    public override fun getFullyQualifiedCallerName(): String {
        return name
    }

    override fun handleNormalizedLoggingCall(
        level: Level,
        marker: Marker?,
        messagePattern: String?,
        arguments: Array<Any>?,
        throwable: Throwable?
    ) {

        val logTag = if (tag != null) {
            tag!!.ifEmpty {
                "yubico-authenticator"
            }
        } else name

        val message = if (tag != null && tag!!.isEmpty()) {
            // the tag was empty string, we suppress showing it in logs
            MessageFormatter.arrayFormat(messagePattern, arguments).message
        } else {
            "[$logTag] ${MessageFormatter.arrayFormat(messagePattern, arguments).message}"
        }

        if (buffer.size > MAX_BUFFER_SIZE) {
            buffer.removeAt(0)
        }
        buffer.add(message)

        if (throwable != null) {
            when (level) {
                Level.INFO -> Log.i(logTag, message, throwable)
                Level.WARN -> Log.w(logTag, message, throwable)
                Level.DEBUG -> Log.d(logTag, message, throwable)
                Level.ERROR -> Log.e(logTag, message, throwable)
                Level.TRACE -> Log.v(logTag, message, throwable)
            }
        } else {
            when (level) {
                Level.INFO -> Log.i(logTag, message)
                Level.WARN -> Log.w(logTag, message)
                Level.DEBUG -> Log.d(logTag, message)
                Level.ERROR -> Log.e(logTag, message)
                Level.TRACE -> Log.v(logTag, message)
            }
        }
    }

    fun setTag(tag: String?) {
        this.tag = tag
    }

    private fun isEnabled(level: Level): Boolean {
        return logLevel.toInt() <= level.toInt()
    }

    companion object {
        private var logLevel = if (BuildConfig.DEBUG) {
            Level.DEBUG
        } else {
            Level.INFO
        }

        private const val MAX_BUFFER_SIZE = 1000
        private val buffer = arrayListOf<String>()

        fun getBuffer(): List<String> {
            return buffer
        }

        fun setLevel(levelString: String?) {
            val level = when (levelString?.uppercase()) {
                "TRAFFIC" -> Level.TRACE
                "DEBUG" -> Level.DEBUG
                "INFO" -> Level.INFO
                "WARNING" -> Level.WARN
                "ERROR" -> Level.ERROR
                else -> Level.INFO
            }
            logLevel = level
        }
    }
}