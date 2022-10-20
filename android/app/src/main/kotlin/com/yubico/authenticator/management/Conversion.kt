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

package com.yubico.authenticator.management

import com.yubico.authenticator.device.Config
import com.yubico.authenticator.device.Info
import com.yubico.authenticator.device.Version
import com.yubico.yubikit.core.Transport
import com.yubico.yubikit.management.DeviceConfig
import com.yubico.yubikit.management.DeviceInfo

fun DeviceConfig.model() = Config(
    deviceFlags = deviceFlags,
    challengeResponseTimeout = challengeResponseTimeout,
    autoEjectTimeout = autoEjectTimeout,
    enabledCapabilities = mapOf(
        "usb" to (getEnabledCapabilities(Transport.USB) ?: 0),
        "nfc" to (getEnabledCapabilities(Transport.NFC) ?: 0)
    )
)

fun DeviceInfo.model(name: String, isNfc: Boolean, usbPid: Int?) = Info(
    config = config.model(),
    serialNumber = serialNumber,
    version = Version(version.major, version.minor, version.micro),
    formFactor = formFactor.value,
    isLocked = isLocked,
    isSky = isSky,
    isFips = isFips,
    name = name,
    isNfc = isNfc,
    usbPid = usbPid,
    supportedCapabilities = mapOf(
        "usb" to getSupportedCapabilities(Transport.USB),
        "nfc" to getSupportedCapabilities(Transport.NFC),
    ).filter { it.value > 0 }
)

