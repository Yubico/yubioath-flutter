/*
 * Copyright (C) 2024 Yubico.
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

import com.yubico.yubikit.fido.ctap.Ctap2Session.InfoData
import kotlinx.serialization.*

typealias YubiKitFidoSession = com.yubico.yubikit.fido.ctap.Ctap2Session

@Serializable
data class Options(
    val clientPin: Boolean,
    val credMgmt: Boolean,
    val credentialMgmtPreview: Boolean,
    val bioEnroll: Boolean?,
    val alwaysUv: Boolean
)

fun Map<String, Any?>.getBoolean(
    key: String,
    default: Boolean = false
): Boolean = get(key) as? Boolean ?: default

fun Map<String, Any?>.getOptionalBoolean(
    key: String
): Boolean? = get(key) as? Boolean

@Serializable
data class SessionInfo(
    val options: Options,
    val aaguid: ByteArray,
    @SerialName("min_pin_length")
    val minPinLength: Int,
    @SerialName("force_pin_change")
    val forcePinChange: Boolean
) {
    constructor(infoData: InfoData) : this(
        Options(
            infoData.options.getBoolean("clientPin"),
            infoData.options.getBoolean("credMgmt"),
            infoData.options.getBoolean("credentialMgmtPreview"),
            infoData.options.getOptionalBoolean("bioEnroll"),
            infoData.options.getBoolean("alwaysUv")
        ),
        infoData.aaguid,
        infoData.minPinLength,
        infoData.forcePinChange
    )

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as SessionInfo

        if (options != other.options) return false
        if (!aaguid.contentEquals(other.aaguid)) return false
        if (minPinLength != other.minPinLength) return false
        return forcePinChange == other.forcePinChange
    }

    override fun hashCode(): Int {
        var result = options.hashCode()
        result = 31 * result + aaguid.contentHashCode()
        result = 31 * result + minPinLength
        result = 31 * result + forcePinChange.hashCode()
        return result
    }

}

@Serializable
data class Session(
    @SerialName("info")
    val info: SessionInfo,
    @SerialName("unlocked")
    val unlocked: Boolean
) {
    constructor(fidoSession: YubiKitFidoSession, unlocked: Boolean) : this(
        SessionInfo(fidoSession.cachedInfo), unlocked
    )
}