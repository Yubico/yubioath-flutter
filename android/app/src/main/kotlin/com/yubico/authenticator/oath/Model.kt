package com.yubico.authenticator.oath

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

class Model {

    enum class OathType(val value: Byte) {
        TOTP(0x20), HOTP(0x10)
    }

    data class Credential(
        val deviceId: String,
        val id: String,
        val oathType: OathType,
        val period: Int,
        val issuer: String? = null,
        val accountName: String,
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

    data class Code(
        val value: String? = null,
        val validFrom: Long,
        val validUntil: Long
    )

    data class CredentialWithCode(
        val credential: Credential,
        val code: Code?
    )

    companion object {

        fun Credential.isInteractive(): Boolean {
            return oathType == OathType.HOTP || (oathType == OathType.TOTP && touchRequired)
        }

        fun Code.toJson() = JsonObject(
            mapOf(
                "value" to JsonPrimitive(value),
                "valid_from" to JsonPrimitive(validFrom / 1000),
                "valid_to" to JsonPrimitive(validUntil / 1000)
            )
        )

        fun Credential.toJson() = JsonObject(
            mapOf(
                "id" to JsonPrimitive(id),
                "device_id" to JsonPrimitive(deviceId),
                "issuer" to JsonPrimitive(issuer),
                "name" to JsonPrimitive(accountName),
                "oath_type" to JsonPrimitive(oathType.value),
                "period" to JsonPrimitive(period),
                "touch_required" to JsonPrimitive(touchRequired),
            )
        )

        fun Pair<Credential, Code?>.toJson() = JsonObject(
            mapOf(
                "credential" to first.toJson(),
                "code" to (second?.toJson() ?: JsonNull)
            )
        )

        fun CredentialWithCode.toJson() = JsonObject(
            mapOf(
                "credential" to credential.toJson(),
                "code" to (code?.toJson() ?: JsonNull)
            )
        )

        fun Map<Credential, Code?>.toJson() = JsonObject(
            mapOf(
                "entries" to JsonArray(
                    map { it.toPair().toJson() }
                )
            )
        )
    }

    var deviceId: String = ""; private set
    var credentials = mutableMapOf<Credential, Code?>(); private set

    // resets the model to initial values
    // used when a usb key has been disconnected
    fun reset() {
        this.credentials.clear()
        this.deviceId = ""
    }

    fun update(deviceId: String, credentials: Map<Credential, Code?>) {
        if (this.deviceId != deviceId) {
            // device was changed, we use the new list
            this.credentials.clear()
            this.credentials.putAll(from = credentials)
            this.deviceId = deviceId
        } else {

            // update codes for non interactive keys
            for ((credential, code) in credentials) {
                if (!credential.isInteractive()) {
                    this.credentials[credential] = code
                }
            }
            // remove obsolete credentials
            this.credentials.filter { entry ->
                // get only keys which are not present in the input map
                //credentials.filter { it.key.id == entry.key.id }.isEmpty()
                !credentials.contains(entry.key)
            }.forEach(action = {
                this.credentials.remove(it.key)
            })
        }
    }

    fun add(deviceId: String, credential: Credential, code: Code?): CredentialWithCode? {
        if (this.deviceId != deviceId) {
            return null
        }

        credentials[credential] = code

        return CredentialWithCode(credential, code)
    }

    fun rename(
        deviceId: String,
        oldCredential: Credential,
        newCredential: Credential
    ): Credential? {
        if (this.deviceId != deviceId) {
            return null
        }

        if (oldCredential.deviceId != newCredential.deviceId) {
            return null
        }

        if (!credentials.contains(oldCredential)) {
            return null
        }

        // preserve code
        val code = credentials[oldCredential]

        credentials.remove(oldCredential)
        credentials[newCredential] = code

        return newCredential
    }

    fun updateCode(deviceId: String, credential: Credential, code: Code?): Code? {
        if (this.deviceId != deviceId) {
            return null
        }

        if (!credentials.contains(credential)) {
            return null
        }

        credentials[credential] = code

        return code
    }
}