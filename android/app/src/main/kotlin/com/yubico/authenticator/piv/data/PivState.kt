/*
 * Copyright (C) 2025 Yubico.
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

package com.yubico.authenticator.piv.data

import com.yubico.authenticator.JsonSerializable
import com.yubico.authenticator.device.Version
import com.yubico.authenticator.jsonSerializer
import com.yubico.authenticator.piv.YubiKitPivSession
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class PivState(
    val version: Version,
    val authenticated: Boolean,
    @SerialName("derived_key")
    val derivedKey: Boolean,
    @SerialName("stored_key")
    val storedKey: Boolean,
    @SerialName("pin_attempts")
    val pinAttempts: Int,
    @SerialName("supports_bio")
    val supportsBio: Boolean,
    val chuid: String?,
    val ccc: String?,
    val metadata: PivStateMetadata?
) : JsonSerializable {

    constructor(
        piv: YubiKitPivSession,
        authenticated: Boolean,
        derivedKey: Boolean,
        storedKey: Boolean,
        supportsBio: Boolean
    ) : this(
        Version(
            piv.version.major,
            piv.version.minor,
            piv.version.micro
        ),
        authenticated,
        derivedKey,
        storedKey,
        piv.pinAttempts,
        supportsBio,
        null,
        null,
        PivStateMetadata(
            ManagementKeyMetadata(piv.managementKeyMetadata),
            PinMetadata(piv.pinMetadata),
            PinMetadata(piv.pukMetadata)
        )

    )

    override fun toJson(): String {
        return jsonSerializer.encodeToString(this)
    }
}
