package com.yubico.authenticator.device

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Info(
    @SerialName("config")
    val config: Config,
    @SerialName("serial")
    val serialNumber: Int?,
    @SerialName("version")
    val version: Version,
    @SerialName("form_factor")
    val formFactor: Int,
    @SerialName("is_locked")
    val isLocked: Boolean,
    @SerialName("is_sky")
    val isSky: Boolean,
    @SerialName("is_fips")
    val isFips: Boolean,
    @SerialName("name")
    val name: String,
    @SerialName("is_nfc")
    val isNfc: Boolean,
    @SerialName("usb_pid")
    val usbPid: Int?,
    @SerialName("supported_capabilities")
    val supportedCapabilities: Map<String, Int>
)