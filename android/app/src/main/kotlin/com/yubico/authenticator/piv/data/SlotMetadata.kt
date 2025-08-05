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

import android.util.Base64
import com.yubico.yubikit.core.keys.PublicKeyValues
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder

typealias YubikitPivSlotMetadata = com.yubico.yubikit.piv.SlotMetadata

@Serializable
data class SlotMetadata(
    @SerialName("key_type")
    val keyType: UByte,
    @SerialName("pin_policy")
    val pinPolicy: Int,
    @SerialName("touch_policy")
    val touchPolicy: Int,
    val generated: Boolean,
    @Serializable(with = PublicKeyValuesAsStringSerializer::class)
    @SerialName("public_key")
    val publicKey: PublicKeyValues? = null
) {
    constructor(slotMetadata: YubikitPivSlotMetadata) : this(
        slotMetadata.keyType.value.toUByte(),
        slotMetadata.pinPolicy.value,
        slotMetadata.touchPolicy.value,
        slotMetadata.isGenerated,
        slotMetadata.publicKeyValues
    )
}

object PublicKeyValuesAsStringSerializer : KSerializer<PublicKeyValues?> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor(
        "PublicKeyValuesAsString",
        PrimitiveKind.STRING
    )

    override fun serialize(encoder: Encoder, value: PublicKeyValues?) {
        encoder.encodeString(value?.let { Base64.encodeToString(it.encoded, 0) } ?: "")
    }

    override fun deserialize(decoder: Decoder): PublicKeyValues? {
        // TODO
        return null
    }
}
