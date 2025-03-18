package com.yubico.authenticator.piv.data

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class PivSlot(
    @SerialName("slot")
    val slotId: Int,
    val metadata: SlotMetadata?,
    @SerialName("cert_info")
    val certInfo: CertInfo?,
    @SerialName("public_key_match")
    val publicKeyMatch: Boolean?
)
