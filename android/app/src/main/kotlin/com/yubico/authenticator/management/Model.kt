package com.yubico.authenticator.management

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

class Model {

    @Serializable
    data class DeviceConfig(
        @SerialName("device_flags")
        val deviceFlags: Int?,
        @SerialName("challenge_response_timeout")
        val challengeResponseTimeout: Byte?,
        @SerialName("auto_eject_timeout")
        val autoEjectTimeout: Short?,
        @SerialName("enabled_capabilities")
        val enabledCapabilities: Map<String, Int>
    )

    @Serializable
    data class AppDeviceInfo(
        @SerialName("config")
        val config: DeviceConfig,
        @SerialName("serial")
        val serialNumber: Int?,
        @SerialName("version")
        val version: List<Byte>,
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

}