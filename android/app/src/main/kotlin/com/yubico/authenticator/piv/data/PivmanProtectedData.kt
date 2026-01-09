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

private const val TLV_TAG_PIVMAN_PROTECTED_DATA = 0x88
private const val TLV_TAG_KEY = 0x89

class PivmanProtectedData(rawData: ByteArray = Tlv(TLV_TAG_PIVMAN_PROTECTED_DATA, null).bytes) {
    var key: ByteArray? = null

    init {
        val tlv = Tlv.parse(rawData)
        val data = Tlvs.decodeMap(tlv.value)
        key = data[TLV_TAG_KEY]
    }

    fun getBytes(): ByteArray {
        var data = ByteArray(0)
        if (key != null) {
            data += Tlv(TLV_TAG_KEY, key).bytes
        }
        return if (data.isNotEmpty()) {
            Tlv(TLV_TAG_PIVMAN_PROTECTED_DATA, data).bytes
        } else {
            ByteArray(
                0
            )
        }
    }
}
