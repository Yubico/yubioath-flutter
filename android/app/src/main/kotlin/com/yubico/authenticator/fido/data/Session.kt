/*
 * Copyright (C) 2024-2025 Yubico.
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

package com.yubico.authenticator.fido.data

import com.yubico.authenticator.JsonSerializable
import com.yubico.authenticator.fido.PersistentPinUvAuthTokenStore
import com.yubico.authenticator.jsonSerializer
import com.yubico.yubikit.fido.client.CredentialManager
import com.yubico.yubikit.fido.ctap.CredentialManagement
import com.yubico.yubikit.fido.ctap.Ctap2Session.InfoData
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

typealias YubiKitFidoSession = com.yubico.yubikit.fido.ctap.Ctap2Session

@Serializable
data class Options(
    val clientPin: Boolean,
    val credMgmt: Boolean,
    val credentialMgmtPreview: Boolean,
    val bioEnroll: Boolean?,
    val alwaysUv: Boolean,
    val ep: Boolean?
) {
    constructor(infoData: InfoData) : this(
        infoData.getOptionsBoolean("clientPin") == true,
        infoData.getOptionsBoolean("credMgmt") == true,
        infoData.getOptionsBoolean("credentialMgmtPreview") == true,
        infoData.getOptionsBoolean("bioEnroll"),
        infoData.getOptionsBoolean("alwaysUv") == true,
        infoData.getOptionsBoolean("ep")
    )

    fun sameDevice(other: Options): Boolean {
        if (this === other) return true

        if (clientPin != other.clientPin) return false
        if (credMgmt != other.credMgmt) return false
        if (credentialMgmtPreview != other.credentialMgmtPreview) return false
        if (bioEnroll != other.bioEnroll) return false
        // alwaysUv may differ
        // ep may differ

        return true
    }

    companion object {
        private fun InfoData.getOptionsBoolean(key: String): Boolean? = options[key] as? Boolean?
    }
}

@Serializable
data class SessionInfo(
    val options: Options,
    val aaguid: ByteArray,
    @SerialName("min_pin_length")
    val minPinLength: Int,
    @SerialName("force_pin_change")
    val forcePinChange: Boolean,
    @SerialName("remaining_disc_creds")
    val remainingDiscoverableCredentials: Int?
) {
    constructor(infoData: InfoData) : this(
        Options(infoData),
        infoData.aaguid,
        infoData.minPinLength,
        infoData.forcePinChange,
        infoData.remainingDiscoverableCredentials
    )

    // this is a more permissive comparison, which does not take in an account properties,
    // which might change by using the FIDO authenticator
    fun sameDevice(other: SessionInfo?): Boolean {
        if (other == null) return false
        if (this === other) return true

        if (!options.sameDevice(other.options)) return false
        if (!aaguid.contentEquals(other.aaguid)) return false
        // minPinLength may differ
        // forcePinChange may differ
        // remainingDiscoverableCredentials may differ

        return true
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as SessionInfo

        if (options != other.options) return false
        if (!aaguid.contentEquals(other.aaguid)) return false
        if (minPinLength != other.minPinLength) return false
        if (forcePinChange != other.forcePinChange) return false
        if (remainingDiscoverableCredentials != other.remainingDiscoverableCredentials) return false

        return true
    }

    override fun hashCode(): Int {
        var result = options.hashCode()
        result = 31 * result + aaguid.contentHashCode()
        result = 31 * result + minPinLength
        result = 31 * result + forcePinChange.hashCode()
        result = 31 * result + (remainingDiscoverableCredentials ?: 0)
        return result
    }
}

@Serializable
data class Session(
    val info: SessionInfo,
    val unlocked: Boolean,
    @SerialName("unlocked_read")
    val unlockedRead: Boolean,
    @SerialName("pin_retries")
    val pinRetries: Int?
) : JsonSerializable {
    constructor(
        infoData: InfoData,
        unlocked: Boolean,
        unlockedRead: Boolean,
        pinRetries: Int?
    ) : this(
        SessionInfo(infoData),
        unlocked,
        unlockedRead,
        pinRetries
    )

    override fun toJson(): String = jsonSerializer.encodeToString(this)
}
