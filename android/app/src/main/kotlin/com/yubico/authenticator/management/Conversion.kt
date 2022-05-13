package com.yubico.authenticator.management

import com.yubico.yubikit.core.Transport
import com.yubico.yubikit.core.Version
import com.yubico.yubikit.management.DeviceConfig
import com.yubico.yubikit.management.DeviceInfo


fun DeviceConfig.model() = Model.DeviceConfig(
    deviceFlags = deviceFlags,
    challengeResponseTimeout = challengeResponseTimeout,
    autoEjectTimeout = autoEjectTimeout,
    enabledCapabilities = mapOf(
        "usb" to (getEnabledCapabilities(Transport.USB) ?: 0),
        "nfc" to (getEnabledCapabilities(Transport.NFC) ?: 0)
    )
)

fun DeviceInfo.model(name: String, isNfc: Boolean, usbPid: Int?) = Model.AppDeviceInfo(
    config = config.model(),
    serialNumber = serialNumber,
    version = listOf(version.major, version.minor, version.micro),
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
    )
)