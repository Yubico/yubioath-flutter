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

package com.yubico.authenticator.oath.data

import com.yubico.authenticator.asString
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

typealias YubiKitCredential = com.yubico.yubikit.oath.Credential
typealias YubiKitOathType = com.yubico.yubikit.oath.OathType

@Serializable
data class Credential(
    @SerialName("device_id")
    val deviceId: String,
    val id: String,
    @SerialName("oath_type")
    val codeType: CodeType,
    val period: Int,
    val issuer: String? = null,
    @SerialName("name")
    val accountName: String,
    @SerialName("touch_required")
    val touchRequired: Boolean
) {

    constructor(credential: YubiKitCredential, deviceId: String) : this(
        deviceId = deviceId,
        id = credential.id.asString(),
        codeType = when (credential.oathType) {
            YubiKitOathType.HOTP -> CodeType.HOTP
            else -> CodeType.TOTP
        },
        period = credential.period,
        issuer = credential.issuer,
        accountName = credential.accountName,
        touchRequired = credential.isTouchRequired
    )

    override fun equals(other: Any?): Boolean =
        (other is Credential) &&
                id == other.id &&
                deviceId == other.deviceId

    override fun hashCode(): Int {
        var result = deviceId.hashCode()
        result = 31 * result + id.hashCode()
        return result
    }
}

@Serializable
data class CredentialWithCode(
    val credential: Credential,
    val code: Code?
)