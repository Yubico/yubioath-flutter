/*
 * Copyright (C) 2023-2025 Yubico.
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
import com.yubico.yubikit.management.Capability
import com.yubico.yubikit.management.FormFactor

val UnknownDevice = Info(
    config = Config(
        deviceFlags = null,
        challengeResponseTimeout = null,
        autoEjectTimeout = null,
        enabledCapabilities = Capabilities()
    ),
    serialNumber = null,
    version = Version(0, 0, 0),
    formFactor = FormFactor.UNKNOWN.value,
    isLocked = false,
    isSky = false,
    isFips = false,
    name = "unknown-device",
    isNfc = false,
    usbPid = null,
    pinComplexity = false,
    supportedCapabilities = Capabilities(),
    fipsCapable = 0,
    fipsApproved = 0,
    resetBlocked = 0,
    versionQualifier = VersionQualifier()
)

fun unknownDeviceWithCapability(transport: Transport, bit: Int = 0): Info {
    val isNfc = transport == Transport.NFC
    val capabilities = Capabilities(
        nfc = if (isNfc) bit else null,
        usb = if (!isNfc) bit else null
    )
    return UnknownDevice.copy(
        isNfc = isNfc,
        config = UnknownDevice.config.copy(enabledCapabilities = capabilities),
        supportedCapabilities = capabilities
    )
}

fun unknownOathDeviceInfo(transport: Transport): Info =
    unknownDeviceWithCapability(transport, Capability.OATH.bit).copy(
        name = "OATH device"
    )

fun unknownFido2DeviceInfo(transport: Transport): Info =
    unknownDeviceWithCapability(transport, Capability.FIDO2.bit).copy(
        name = "FIDO2 device"
    )

fun restrictedNfcDeviceInfo(transport: Transport): Info {
    if (transport != Transport.NFC) {
        return UnknownDevice
    }

    return UnknownDevice.copy(
        isNfc = true,
        name = "restricted-nfc"
    )
}

// the YubiKey requires SCP11b communication but the phone cannot handle it
val noScp11bNfcSupport = UnknownDevice.copy(
    isNfc = true,
    name = "no-scp11b-nfc-support"
)
