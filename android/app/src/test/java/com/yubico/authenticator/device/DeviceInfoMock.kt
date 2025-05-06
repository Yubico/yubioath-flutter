package com.yubico.authenticator.device

import com.yubico.yubikit.core.Transport
import com.yubico.yubikit.core.Version
import com.yubico.yubikit.management.DeviceInfo
import com.yubico.yubikit.management.FormFactor
import com.yubico.yubikit.management.VersionQualifier
import org.mockito.Mockito
import org.mockito.Mockito.`when`

val deviceInfoMock: DeviceInfo
    get() = Mockito.mock(DeviceInfo::class.java).also {
        val deviceConfig = deviceConfigMock
        `when`(it.config).thenReturn(deviceConfig)
        `when`(it.version).thenReturn(Version(0, 0, 0))
        `when`(it.serialNumber).thenReturn(0)
        `when`(it.formFactor).thenReturn(FormFactor.USB_A_NANO)
        `when`(it.isLocked).thenReturn(false)
        `when`(it.isSky).thenReturn(false)
        `when`(it.isFips).thenReturn(false)
        `when`(it.hasTransport(Transport.NFC)).thenReturn(false)
        `when`(it.hasTransport(Transport.USB)).thenReturn(false)
        `when`(it.getSupportedCapabilities(Transport.USB)).thenReturn(0)
        `when`(it.getSupportedCapabilities(Transport.NFC)).thenReturn(0)
        `when`(it.versionQualifier).thenReturn(
            VersionQualifier(
                Version(0, 0, 0),
                VersionQualifier.Type.FINAL,
                0
            )
        )
    }