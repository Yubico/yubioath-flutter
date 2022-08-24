package com.yubico.authenticator.oath

import com.yubico.authenticator.device.Version
import kotlinx.serialization.*
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder

class Model {

    @Serializable
    data class Session(
        @SerialName("device_id")
        val deviceId: String,
        @SerialName("version")
        val version: Version,
        @SerialName("has_key")
        val isAccessKeySet: Boolean,
        @SerialName("remembered")
        val isRemembered: Boolean,
        @SerialName("locked")
        val isLocked: Boolean
    ) {
        @SerialName("keystore")
        @Suppress("unused")
        val keystoreState: String = "unknown"
    }

    @Serializable(with = OathTypeSerializer::class)
    enum class OathType(val value: Byte) {
        TOTP(0x20),
        HOTP(0x10);
    }

    @Serializable
    data class Credential(
        @SerialName("device_id")
        val deviceId: String,
        val id: String,
        @SerialName("oath_type")
        val oathType: OathType,
        val period: Int,
        val issuer: String? = null,
        @SerialName("name")
        val accountName: String,
        @SerialName("touch_required")
        val touchRequired: Boolean
    ) {
        override fun equals(other: Any?): Boolean =
            (other is Credential) && id == other.id && deviceId == other.deviceId

        override fun hashCode(): Int {
            var result = deviceId.hashCode()
            result = 31 * result + id.hashCode()
            return result
        }
    }


    @Serializable
    class Code(
        val value: String? = null,
        @SerialName("valid_from")
        @Suppress("unused")
        val validFrom: Long,
        @SerialName("valid_to")
        @Suppress("unused")
        val validTo: Long
    ) {
        override fun toString(): String {
            return "[value: $value, valid_from: $validFrom, valid_to: $validTo}"
        }
    }

    @Serializable
    data class CredentialWithCode(
        val credential: Credential,
        val code: Code?
    )

    object OathTypeSerializer : KSerializer<OathType> {
        override fun deserialize(decoder: Decoder): OathType =
            when (decoder.decodeByte()) {
                OathType.HOTP.value -> OathType.HOTP
                OathType.TOTP.value -> OathType.TOTP
                else -> throw IllegalArgumentException()
            }

        override val descriptor: SerialDescriptor =
            PrimitiveSerialDescriptor("OathType", PrimitiveKind.BYTE)

        override fun serialize(encoder: Encoder, value: OathType) {
            encoder.encodeByte(value = value.value)
        }

    }
}