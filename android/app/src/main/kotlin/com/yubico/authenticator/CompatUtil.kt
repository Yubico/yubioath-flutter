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
package com.yubico.authenticator

import android.os.Build

/**
 * Utility class for handling Android SDK compatibility in a testable way.
 *
 * Replaces runtime check with simple methods. The following code
 * ```
 * if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) { doFromM() } else { doUntilM() }
 * ```
 * can be rewritten as
 * ```
 * val compatUtil = CompatUtil(Build.VERSION.SDK_INT)
 * compatUtil.from(Build.VERSION_CODES.M) {
 *    doFromM()
 * }.otherwise {
 *    doUntilM()
 * }
 * ```
 *
 * @param sdkVersion the version this instance uses for compatibility checking. The release app
 * uses `Build.VERSION.SDK_INT`, tests use appropriate other values.
 */
@Suppress("MemberVisibilityCanBePrivate", "unused")
class CompatUtil(private val sdkVersion: Int) {
    /**
     * Wrapper class holding values computed by [CompatUtil]
     */
    class CompatValue<T>() {
        var value: T? = null
        var isValid: Boolean = false

        constructor(value: T) : this() {
            this.value = value
            isValid = true
        }

        /**
         * @return unwrapped value if valid or result of [block]
         */
        @Suppress("UNCHECKED_CAST")
        fun otherwise(block: () -> T): T =
            if (isValid) {
                if (value == null) {
                    null as T
                } else {
                    value!!
                }
            } else {
                block()
            }

        /**
         * @return unwrapped value if valid or [value]
         */
        fun otherwise(value: T): T = otherwise { value }
    }

    /**
     * Execute [block] only on devices running lower sdk version than [version]
     *
     * @return wrapped value
     */
    fun <T> until(version: Int, block: () -> T): CompatValue<T> =
        if (sdkVersion < version) {
            CompatValue(block())
        } else {
            CompatValue()
        }

    /**
     * Execute [block] only on devices running higher or equal sdk version than [version]
     *
     * @return wrapped value
     */
    fun <T> from(version: Int, block: () -> T): CompatValue<T> =
        if (sdkVersion >= version) {
            CompatValue(block())
        } else {
            CompatValue()
        }
}

val compatUtil = CompatUtil(Build.VERSION.SDK_INT)