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
