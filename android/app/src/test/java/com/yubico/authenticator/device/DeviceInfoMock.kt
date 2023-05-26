package com.yubico.authenticator.device

import com.yubico.yubikit.core.Transport
import com.yubico.yubikit.core.Version
import com.yubico.yubikit.management.DeviceInfo
import com.yubico.yubikit.management.FormFactor
import org.mockito.Mockito

val deviceInfoMock: DeviceInfo
    get() = Mockito.mock(DeviceInfo::class.java).also {
        val deviceConfig = deviceConfigMock
        Mockito.`when`(it.config).thenReturn(deviceConfig)
        Mockito.`when`(it.version).thenReturn(Version(0, 0, 0))
        Mockito.`when`(it.serialNumber).thenReturn(0)
        Mockito.`when`(it.formFactor).thenReturn(FormFactor.USB_A_NANO)
        Mockito.`when`(it.isLocked).thenReturn(false)
        Mockito.`when`(it.isSky).thenReturn(false)
        Mockito.`when`(it.isFips).thenReturn(false)
        Mockito.`when`(it.hasTransport(Transport.NFC)).thenReturn(false)
        Mockito.`when`(it.hasTransport(Transport.USB)).thenReturn(false)
        Mockito.`when`(it.getSupportedCapabilities(Transport.USB)).thenReturn(0)
        Mockito.`when`(it.getSupportedCapabilities(Transport.NFC)).thenReturn(0)
    }