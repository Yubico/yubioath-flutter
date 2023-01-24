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
package com.yubico.authenticator

import android.os.Build

class SdkVersion(private val sdk: Int) {
    fun <T> fromVersion(version: Int, block: () -> T, or: () -> T): T =
        if (sdk >= version) {
            block()
        } else {
            or()
        }

    fun <T> beforeVersion(version: Int, block: () -> T, or: () -> T): T =
        fromVersion(version, or, block)

    fun fromVersion(version: Int, block: () -> Unit) {
        fromVersion(version, block) {}
    }

    fun beforeVersion(version: Int, block: () -> Unit) {
        fromVersion(version, {}, block)
    }

    fun <T> fromVersion(version: Int, holds: T, or: T): T =
        if (sdk >= version) {
            holds
        } else {
            or
        }
}

val sdkVersion = SdkVersion(Build.VERSION.SDK_INT)