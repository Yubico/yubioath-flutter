/*
 * Copyright (C) 2022-2023 Yubico.
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

package com.yubico.authenticator.device

import com.yubico.yubikit.core.Transport
import com.yubico.yubikit.management.DeviceInfo
import com.yubico.yubikit.management.FormFactor
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Info(
    @SerialName("config")
    val config : Config,
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
    val supportedCapabilities: Capabilities
) {
    constructor(name: String, isNfc: Boolean, usbPid: Int?, deviceInfo: DeviceInfo) : this(
        config = Config(deviceInfo.config),
        serialNumber = deviceInfo.serialNumber,
        version = Version(deviceInfo.version.major, deviceInfo.version.minor, deviceInfo.version.micro),
        formFactor = deviceInfo.formFactor.value,
        isLocked = deviceInfo.isLocked,
        isSky = deviceInfo.isSky,
        isFips = deviceInfo.isFips,
        name = name,
        isNfc = isNfc,
        usbPid = usbPid,
        supportedCapabilities = Capabilities(
            nfc = deviceInfo.getSupportedCapabilities(Transport.NFC),
            usb = deviceInfo.getSupportedCapabilities(Transport.USB)
        )
    )
}
