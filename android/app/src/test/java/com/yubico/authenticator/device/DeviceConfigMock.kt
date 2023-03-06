package com.yubico.authenticator.device

import com.yubico.yubikit.core.Transport
import com.yubico.yubikit.management.DeviceConfig
import org.mockito.Mockito

val deviceConfigMock: DeviceConfig
    get() = Mockito.mock(DeviceConfig::class.java).also {
        Mockito.`when`(it.autoEjectTimeout).thenReturn(null)
        Mockito.`when`(it.challengeResponseTimeout).thenReturn(null)
        Mockito.`when`(it.deviceFlags).thenReturn(null)
        Mockito.`when`(it.getEnabledCapabilities(Transport.NFC)).thenReturn(null)
        Mockito.`when`(it.getEnabledCapabilities(Transport.USB)).thenReturn(null)
    }