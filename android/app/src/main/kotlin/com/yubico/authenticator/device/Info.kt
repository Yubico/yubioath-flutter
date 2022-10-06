/*
 * Copyright (C) 2022 Yubico.
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