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
import java.lang.reflect.Field
import java.lang.reflect.Modifier

object TestUtil {
    fun mockSdkInt(sdkInt: Int) {
        val versionField = Build.VERSION::class.java.getField("SDK_INT")
        versionField.isAccessible = true
        Field::class.java.getDeclaredField("modifiers").apply {
            isAccessible = true
            setInt(versionField, versionField.modifiers and Modifier.FINAL.inv())
        }
        versionField.set(null, sdkInt)
    }
}