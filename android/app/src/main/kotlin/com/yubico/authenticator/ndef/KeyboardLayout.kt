package com.yubico.authenticator.ndef

import java.lang.IllegalArgumentException

abstract class KeyboardLayout(val name:String) {
    companion object {
        const val DEFAULT_NAME = "US"

        const val SHIFT = 0x80

        private val layouts by lazy {
            listOf(
                    USKeyboardLayout,
                    DEKeyboardLayout,
                    DECHKeyboardLayout
            ).map { it.name to it }.toMap()
        }

        val availableLayouts get() = layouts.keys.toTypedArray()
        fun forName(name:String) = layouts[name] ?: throw IllegalArgumentException("Unsupported keyboard layout: $name!")
    }

    abstract fun fromScanCode(code: Int): String

    fun fromScanCodes(bytes:ByteArray):String = bytes.joinToString("") {
        fromScanCode(it.toInt() and 0xff)
    }
}

open class BaseKeyboardLayout(name:String, private val unshiftedMap: Array<String>, private val shiftedMap: Array<String>) : KeyboardLayout(name) {
    override fun fromScanCode(code: Int): String {
        if (code < KeyboardLayout.SHIFT) {
            if (code < unshiftedMap.size) {
                return unshiftedMap[code]
            }
        } else {
            val shiftCode = code xor KeyboardLayout.SHIFT
            if (shiftCode < shiftedMap.size) {
                return shiftedMap[shiftCode]
            }
        }

        return ""
    }
}