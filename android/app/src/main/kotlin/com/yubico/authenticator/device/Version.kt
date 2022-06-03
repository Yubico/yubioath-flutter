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