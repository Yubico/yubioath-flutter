package com.yubico.authenticator.data.oath

import com.yubico.yubikit.oath.Code
import com.yubico.yubikit.oath.Credential
import com.yubico.yubikit.oath.OathSession
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

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

fun Credential.idAsString() = id.joinToString(
    separator = ""
) { b -> "%02x".format(b) }

fun Credential.toJson(deviceId: String) = JsonObject(
    mapOf(
        "id" to JsonPrimitive(idAsString()),
        "device_id" to JsonPrimitive(deviceId),
        "issuer" to JsonPrimitive(issuer),
        "name" to JsonPrimitive(accountName),
        "oath_type" to JsonPrimitive(oathType.value),
        "period" to JsonPrimitive(period),
        "touch_required" to JsonPrimitive(isTouchRequired),
    )
)

fun Map<Credential, Code?>.toJson(deviceId: String) = JsonObject(
    mapOf(
        "entries" to JsonArray(
            map { it.toPair().toJson(deviceId) }
        )
    )
)

fun Pair<Credential, Code?>.toJson(deviceId: String) = JsonObject(
    mapOf(
        "credential" to first.toJson(deviceId),
        "code" to (second?.toJson() ?: JsonNull)
    )
)

fun computeUnlockOathSessionValue(isLocked: Boolean, isRemembered: Boolean) : Long {
    val lockBit = 0x1L
    val rememberBit = 0x2L

    return (if (isLocked) lockBit else 0L) or (if (isRemembered) rememberBit else 0L)
}
