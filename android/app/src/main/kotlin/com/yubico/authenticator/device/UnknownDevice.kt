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
    name = "Unrecognized device",
    isNfc = false,
    usbPid = null,
    pinComplexity = false,
    supportedCapabilities = Capabilities()
)

fun unknownDeviceWithCapability(transport: Transport, bit: Int = 0) : Info {
    val isNfc = transport == Transport.NFC
    val capabilities = Capabilities(
        nfc = if (isNfc)  bit else null,
        usb = if (!isNfc) bit else null
    )
    return UnknownDevice.copy(
        isNfc = isNfc,
        config = UnknownDevice.config.copy(enabledCapabilities = capabilities),
        supportedCapabilities = capabilities
    )
}

fun unknownOathDeviceInfo(transport: Transport) : Info {
    return unknownDeviceWithCapability(transport, Capability.OATH.bit).copy(
        name = "OATH device"
    )
}

fun unknownFido2DeviceInfo(transport: Transport) : Info {
    return unknownDeviceWithCapability(transport, Capability.FIDO2.bit).copy(
        name = "FIDO2 device"
    )
}