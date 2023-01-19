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

package com.yubico.authenticator.device

import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.MapSerializer
import kotlinx.serialization.builtins.serializer
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder

@Serializable(with = CapabilitiesSerializer::class)
data class Capabilities(val usb: Int? = null, val nfc: Int? = null)

object CapabilitiesSerializer : KSerializer<Capabilities> {
    private val serializer =
        MapSerializer(String.Companion.serializer(), Int.Companion.serializer())
    override val descriptor: SerialDescriptor = serializer.descriptor

    override fun serialize(encoder: Encoder, value: Capabilities) {
        encoder.encodeSerializableValue(
            serializer,
            buildMap {
                value.nfc?.let { put(TAG_NFC, it) }
                value.usb?.let { put(TAG_USB, it) }
            }
        )
    }

    override fun deserialize(decoder: Decoder): Capabilities {
        return try {
            val map = decoder.decodeSerializableValue(serializer)
            Capabilities(
                usb = map.getOrElse(TAG_USB) { null },
                nfc = map.getOrElse(TAG_NFC) { null }
            )
        } catch (e: Exception) {
            Capabilities()
        }
    }

    private const val TAG_USB = "usb"
    private const val TAG_NFC = "nfc"
}