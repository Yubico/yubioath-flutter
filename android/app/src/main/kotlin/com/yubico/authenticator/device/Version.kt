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

package com.yubico.authenticator.device

import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ByteArraySerializer
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder

@Serializable(with = VersionSerializer::class)
data class Version(
    val major: Byte,
    val minor: Byte,
    val micro: Byte
)

object VersionSerializer : KSerializer<Version> {
    override val descriptor: SerialDescriptor = ByteArraySerializer().descriptor

    override fun serialize(encoder: Encoder, value: Version) {
        encoder.encodeSerializableValue(
            ByteArraySerializer(),
            byteArrayOf(value.major, value.minor, value.micro)
        )
    }

    override fun deserialize(decoder: Decoder): Version {
        val byteArray = decoder.decodeSerializableValue(ByteArraySerializer())
        val major = if (byteArray.isNotEmpty()) byteArray[0] else 0
        val minor = if (byteArray.size > 1) byteArray[1] else 0
        val micro = if (byteArray.size > 2) byteArray[2] else 0
        return Version(major, minor, micro)
    }
}