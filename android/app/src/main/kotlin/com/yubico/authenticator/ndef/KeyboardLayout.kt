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

package com.yubico.authenticator.ndef

import java.lang.IllegalArgumentException

abstract class KeyboardLayout(val name:String) {
    companion object {
        const val SHIFT = 0x80

        private val layouts by lazy {
            listOf(
                USKeyboardLayout,
                DEKeyboardLayout,
                DECHKeyboardLayout
            ).associateBy { it.name }
        }

        fun forName(name:String) = layouts[name] ?: throw IllegalArgumentException("Unsupported keyboard layout: $name!")
    }

    abstract fun fromScanCode(code: Int): String

    fun fromScanCodes(bytes:ByteArray):String = bytes.joinToString("") {
        fromScanCode(it.toInt() and 0xff)
    }
}

open class BaseKeyboardLayout(name:String, private val unshiftedMap: Array<String>, private val shiftedMap: Array<String>) : KeyboardLayout(name) {
    override fun fromScanCode(code: Int): String {
        if (code < SHIFT) {
            if (code < unshiftedMap.size) {
                return unshiftedMap[code]
            }
        } else {
            val shiftCode = code xor SHIFT
            if (shiftCode < shiftedMap.size) {
                return shiftedMap[shiftCode]
            }
        }

        return ""
    }
}