package com.yubico.authenticator.device

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Config(
    @SerialName("device_flags")
    val deviceFlags: Int?,
    @SerialName("challenge_response_timeout")
    val challengeResponseTimeout: Byte?,
    @SerialName("auto_eject_timeout")
    val autoEjectTimeout: Short?,
    @SerialName("enabled_capabilities")
    val enabledCapabilities: Map<String, Int>
)