/*
 * Copyright (C) 2025 Yubico.
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

package com.yubico.authenticator.piv.data

import com.yubico.yubikit.core.util.Tlv
import com.yubico.yubikit.core.util.Tlvs
import java.nio.ByteBuffer

private const val FLAG_PUK_BLOCKED = 0x01
private const val FLAG_MGM_KEY_PROTECTED = 0x02

private const val TLV_TAG_PIVMAN_DATA = 0x80
private const val TLV_TAG_FLAGS = 0x81
private const val TLV_TAG_SALT = 0x82
private const val TLV_TAG_TIMESTAMP = 0x83

class PivmanData(rawData: ByteArray = Tlv(TLV_TAG_PIVMAN_DATA, null).bytes) {

    private var _flags: Int? = null
    var salt: ByteArray? = null
    var pinTimestamp: Int? = null

    init {
        val data = Tlvs.decodeMap(Tlv.parse(rawData).value)
        _flags = data[TLV_TAG_FLAGS]?.let {
            ByteBuffer.wrap(it).get().toInt() and 0xFF
        }
        salt = data[TLV_TAG_SALT]
        pinTimestamp = data[TLV_TAG_TIMESTAMP]?.let { ByteBuffer.wrap(it).int }
    }

    private fun getFlag(mask: Int): Boolean = ((_flags ?: 0) and mask) != 0

    private fun setFlag(mask: Int, value: Boolean) {
        if (value) {
            _flags = (_flags ?: 0) or mask
        } else if (_flags != null) {
            _flags = _flags!! and mask.inv()
        }
    }

    var pukBlocked: Boolean
        get() = getFlag(FLAG_PUK_BLOCKED)
        set(value) = setFlag(FLAG_PUK_BLOCKED, value)

    var mgmKeyProtected: Boolean
        get() = getFlag(FLAG_MGM_KEY_PROTECTED)
        set(value) = setFlag(FLAG_MGM_KEY_PROTECTED, value)

    val hasProtectedKey: Boolean
        get() = hasDerivedKey || hasStoredKey

    val hasDerivedKey: Boolean
        get() = salt != null

    val hasStoredKey: Boolean
        get() = mgmKeyProtected

    fun getBytes(): ByteArray {
        var data = ByteArray(0)
        if (_flags != null) {
            val flagBytes = ByteBuffer.allocate(1).put(_flags!!.toByte()).array()
            data += Tlv(TLV_TAG_FLAGS, flagBytes).bytes
        }
        if (salt != null) {
            data += Tlv(TLV_TAG_SALT, salt).bytes
        }
        if (pinTimestamp != null) {
            val tsBytes = ByteBuffer.allocate(4).putInt(pinTimestamp!!).array()
            data += Tlv(TLV_TAG_TIMESTAMP, tsBytes).bytes
        }
        return if (data.isNotEmpty()) Tlv(TLV_TAG_PIVMAN_DATA, data).bytes else ByteArray(0)
    }
}