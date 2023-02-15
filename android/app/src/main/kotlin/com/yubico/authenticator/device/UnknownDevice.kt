package com.yubico.authenticator.device

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
    supportedCapabilities = Capabilities()
)