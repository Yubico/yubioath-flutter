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
import com.yubico.yubikit.management.DeviceConfig
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Config(
    @SerialName("device_flags")
    val deviceFlags: Int?,
    @SerialName("challenge_response_timeout")
    val challengeResponseTimeout: UByte?,
    @SerialName("auto_eject_timeout")
    val autoEjectTimeout: UShort?,
    @SerialName("enabled_capabilities")
    val enabledCapabilities: Capabilities
) {
    constructor(deviceConfig: DeviceConfig) : this(
        deviceFlags = deviceConfig.deviceFlags,
        challengeResponseTimeout = deviceConfig.challengeResponseTimeout?.toUByte(),
        autoEjectTimeout = deviceConfig.autoEjectTimeout?.toUShort(),
        enabledCapabilities = Capabilities(
            nfc = deviceConfig.getEnabledCapabilities(Transport.NFC) ?: 0,
            usb = deviceConfig.getEnabledCapabilities(Transport.USB) ?: 0
        )
    )
}

