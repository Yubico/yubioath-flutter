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

package com.yubico.authenticator.oath.data

import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder


@Serializable(with = OathTypeSerializer::class)
enum class CodeType(val value: Byte) {
    TOTP(0x20),
    HOTP(0x10);
}

object OathTypeSerializer : KSerializer<CodeType> {
    override fun deserialize(decoder: Decoder): CodeType =
        when (decoder.decodeByte()) {
            CodeType.HOTP.value -> CodeType.HOTP
            CodeType.TOTP.value -> CodeType.TOTP
            else -> throw IllegalArgumentException()
        }

    override val descriptor: SerialDescriptor =
        PrimitiveSerialDescriptor("OathType", PrimitiveKind.BYTE)

    override fun serialize(encoder: Encoder, value: CodeType) {
        encoder.encodeByte(value = value.value)
    }

}