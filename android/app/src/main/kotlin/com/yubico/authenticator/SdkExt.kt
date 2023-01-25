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

package com.yubico.authenticator

import android.annotation.TargetApi
import android.content.Intent
import android.os.Build
import android.os.Parcelable

inline fun <reified T : Parcelable> Intent.parcelableExtra(name: String): T? =
    compatUtil.from(Build.VERSION_CODES.TIRAMISU) {
        CompatHelper.getParcelableExtraT(this, name, T::class.java)
    }.otherwise(
        @Suppress("deprecation") getParcelableExtra(name) as? T
    )

inline fun <reified T : Parcelable> Intent.parcelableArrayExtra(name: String): Array<out T>? =
    compatUtil.from(Build.VERSION_CODES.TIRAMISU) {
        CompatHelper.getParcelableArrayExtraT(this, name, T::class.java)
    }.otherwise(
        @Suppress("deprecation")
        getParcelableArrayExtra(name)
            ?.filterIsInstance<T>()
            ?.toTypedArray()
    )

class CompatHelper {
    companion object {
        @TargetApi(Build.VERSION_CODES.TIRAMISU)
        inline fun <reified T : Parcelable> getParcelableExtraT(
            intent: Intent,
            name: String,
            clazz: Class<T>
        ) = intent.getParcelableExtra(name, clazz)

        @TargetApi(Build.VERSION_CODES.TIRAMISU)
        inline fun <reified T : Parcelable> getParcelableArrayExtraT(
            intent: Intent,
            name: String,
            clazz: Class<T>
        ): Array<T>? = intent.getParcelableArrayExtra(name, clazz)
    }
}