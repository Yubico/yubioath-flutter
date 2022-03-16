package com.yubico.authenticator

import com.yubico.yubikit.core.Transport
import com.yubico.yubikit.core.Version
import com.yubico.yubikit.management.DeviceConfig
import com.yubico.yubikit.management.DeviceInfo
import com.yubico.yubikit.oath.Code
import com.yubico.yubikit.oath.Credential
import com.yubico.yubikit.oath.OathSession
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

class SerializeHelpers {
    companion object {
        private fun serialize(config: DeviceConfig) = with(config) {
            JsonObject(
                mapOf(
                    "device_flags" to JsonPrimitive(deviceFlags),
                    "challenge_response_timeout" to JsonPrimitive(challengeResponseTimeout),
                    "auto_eject_timeout" to JsonPrimitive(autoEjectTimeout),
                    "enabled_capabilities" to JsonObject(
                        mapOf(
                            "usb" to JsonPrimitive(getEnabledCapabilities(Transport.USB) ?: 0),
                            "nfc" to JsonPrimitive(getEnabledCapabilities(Transport.NFC) ?: 0),
                        )
                    )
                )
            )
        }

        private fun serialize(version: Version) = with(version) {
            JsonArray(
                listOf(
                    JsonPrimitive(major),
                    JsonPrimitive(minor),
                    JsonPrimitive(micro)
                )
            )
        }

        fun DeviceInfo.toJson(isNfcDevice: Boolean) = JsonObject(
            mapOf(
                "config" to serialize(config),
                "serial" to JsonPrimitive(serialNumber),
                "version" to serialize(version),
                "form_factor" to JsonPrimitive(formFactor.value),
                "is_locked" to JsonPrimitive(isLocked),
                "is_sky" to JsonPrimitive(false),  // FIXME return correct value
                "is_fips" to JsonPrimitive(false), // FIXME return correct value
                "name" to JsonPrimitive("FIXME"),  // FIXME return correct value
                "isNFC" to JsonPrimitive(isNfcDevice),
                "supported_capabilities" to JsonObject(
                    mapOf(
                        "usb" to JsonPrimitive(getSupportedCapabilities(Transport.USB)),
                        "nfc" to JsonPrimitive(getSupportedCapabilities(Transport.NFC)),
                    )
                )
            )
        )

        fun OathSession.toJson(remembered: Boolean) = JsonObject(
            mapOf(
                "deviceId" to JsonPrimitive(deviceId),
                "hasKey" to JsonPrimitive(isAccessKeySet),
                "remembered" to JsonPrimitive(remembered),
                "locked" to JsonPrimitive(isLocked)
            )
        )

        fun Code.toJson() = JsonObject(
            mapOf(
                "value" to JsonPrimitive(value),
                "valid_from" to JsonPrimitive(validFrom / 1000),
                "valid_to" to JsonPrimitive(validUntil / 1000)
            )
        )

        fun credentialIdAsString(id: ByteArray): String = id.joinToString(
            separator = ""
        ) { b -> "%02x".format(b) }

        fun Credential.toJson(deviceId: String) =
            JsonObject(
                mapOf(
                    "id" to JsonPrimitive(
                        credentialIdAsString(id)
                    ),
                    "device_id" to JsonPrimitive(deviceId),
                    "issuer" to JsonPrimitive(issuer),
                    "name" to JsonPrimitive(accountName),
                    "oath_type" to JsonPrimitive(oathType.value),
                    "period" to JsonPrimitive(period),
                    "touch_required" to JsonPrimitive(isTouchRequired),
                )
            )

        fun Map<Credential, Code?>.toJson(deviceId: String) =
            JsonObject(
                mapOf(
                    "entries" to JsonArray(
                        map { (credential, code) ->
                            JsonObject(
                                mapOf(
                                    "credential" to credential.toJson(deviceId),
                                    "code" to (code?.toJson() ?: JsonNull)
                                )
                            )
                        }
                    )
                )
            )
    }
}