package com.yubico.authenticator.oath

import com.yubico.authenticator.device.Version
import com.yubico.yubikit.oath.Code
import com.yubico.yubikit.oath.Credential
import com.yubico.yubikit.oath.OathSession
import com.yubico.yubikit.oath.OathType

fun ByteArray.asString() = joinToString(
    separator = ""
) { b -> "%02x".format(b) }

// convert yubikit types to Model types
fun OathSession.model(isRemembered: Boolean) = Model.Session(
    deviceId,
    Version(
        version.major,
        version.minor,
        version.micro
    ),
    isAccessKeySet,
    isRemembered,
    isLocked
)

fun Credential.model(deviceId: String) = Model.Credential(
    deviceId = deviceId,
    id = id.asString(),
    oathType = when (oathType) {
        OathType.HOTP -> Model.OathType.HOTP
        else -> Model.OathType.TOTP
    },
    period = period,
    issuer = issuer,
    accountName = accountName,
    touchRequired = isTouchRequired
)

fun Code.model() = Model.Code(
    value,
    validFrom / 1000,
    validUntil / 1000
)

fun Map<Credential, Code?>.model(deviceId: String): Map<Model.Credential, Model.Code?> =
    map { (credential, code) ->
        Pair(
            credential.model(deviceId),
            code?.model()
        )
    }.toMap()
