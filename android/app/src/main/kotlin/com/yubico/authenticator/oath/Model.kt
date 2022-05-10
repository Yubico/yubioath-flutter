package com.yubico.authenticator.oath

import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder

fun Model.Credential.isInteractive(): Boolean {
    return oathType == Model.OathType.HOTP || (oathType == Model.OathType.TOTP && touchRequired)
}

class Model {

    @Serializable
    data class Session(
        @SerialName("device_id")
        val deviceId: String = "",
        @SerialName("has_key")
        val isAccessKeySet: Boolean = false,
        @SerialName("remembered")
        val isRemembered: Boolean = false,
        @SerialName("locked")
        val isLocked: Boolean = false,
        @SerialName("keystore")
        val keystoreState: String = "unknown"
    )

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
    )

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

    private var _credentials = mutableMapOf<Credential, Code?>(); private set

    var session = Session()
    val credentials: List<CredentialWithCode>
        get() = _credentials.map {
            CredentialWithCode(it.key, it.value)
        }

    // resets the model to initial values
    // used when a usb key has been disconnected
    fun reset() {
        this._credentials.clear()
        this.session = Session()
    }

    fun update(deviceId: String, credentials: Map<Credential, Code?>) {

        // is the model already holding credentials for the deviceId
        val sameDevice = this._credentials.keys.firstOrNull()?.deviceId == deviceId

        if (!sameDevice) {
            // device was changed, we use the new list
            this._credentials.clear()
            this._credentials.putAll(from = credentials)
            this.session = Session(deviceId)
        } else {

            // update codes for non interactive keys
            for ((credential, code) in credentials) {
                if (!credential.isInteractive() || !this._credentials.contains(credential)) {
                    this._credentials[credential] = code
                }
            }
            // remove obsolete credentials
            this._credentials.filter { entry ->
                // get only keys which are not present in the input map
                !credentials.contains(entry.key)
            }.forEach(action = {
                this._credentials.remove(it.key)
            })
        }
    }

    fun add(deviceId: String, credential: Credential, code: Code?): CredentialWithCode? {
        if (this.session.deviceId != deviceId) {
            return null
        }

        _credentials[credential] = code

        return CredentialWithCode(credential, code)
    }

    fun rename(
        deviceId: String,
        oldCredential: Credential,
        newCredential: Credential
    ): Credential? {
        if (this.session.deviceId != deviceId) {
            return null
        }

        if (oldCredential.deviceId != newCredential.deviceId) {
            return null
        }

        if (!_credentials.contains(oldCredential)) {
            return null
        }

        // preserve code
        val code = _credentials[oldCredential]

        _credentials.remove(oldCredential)
        _credentials[newCredential] = code

        return newCredential
    }

    fun updateCode(deviceId: String, credential: Credential, code: Code?): Code? {
        if (this.session.deviceId != deviceId) {
            return null
        }

        if (!_credentials.contains(credential)) {
            return null
        }

        _credentials[credential] = code

        return code
    }
}