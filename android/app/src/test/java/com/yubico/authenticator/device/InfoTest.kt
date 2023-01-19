/*
 * Copyright (C) 2023 Yubico.
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
import com.yubico.yubikit.core.Version
import com.yubico.yubikit.management.DeviceConfig
import com.yubico.yubikit.management.DeviceInfo
import com.yubico.yubikit.management.FormFactor
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.mockito.Mockito.mock
import org.mockito.Mockito.`when`

class InfoTest {

    @Test
    fun construction() {
        val deviceInfo = mock(DeviceInfo::class.java)
        val deviceConfig = mock(DeviceConfig::class.java)

        `when`(deviceInfo.config).thenReturn(deviceConfig)
        `when`(deviceInfo.serialNumber).thenReturn(1234)
        `when`(deviceInfo.version).thenReturn(Version(1, 2, 3))
        `when`(deviceInfo.formFactor).thenReturn(FormFactor.USB_A_NANO)
        `when`(deviceInfo.isLocked).thenReturn(true)
        `when`(deviceInfo.isSky).thenReturn(false)
        `when`(deviceInfo.isFips).thenReturn(true)
        `when`(deviceInfo.getSupportedCapabilities(Transport.USB)).thenReturn(456)
        `when`(deviceInfo.getSupportedCapabilities(Transport.NFC)).thenReturn(789)

        val info =
            Info(name = "Tested Device", isNfc = true, usbPid = null, deviceInfo = deviceInfo)

        assertEquals(Config(deviceConfig), info.config)
        assertEquals(1234, info.serialNumber)
        assertEquals(Version(1, 2, 3).major, info.version.major)
        assertEquals(Version(1, 2, 3).minor, info.version.minor)
        assertEquals(Version(1, 2, 3).micro, info.version.micro)
        assertEquals(FormFactor.USB_A_NANO.value, info.formFactor)
        assertTrue(info.isLocked)
        assertFalse(info.isSky)
        assertTrue(info.isFips)
        assertEquals(456, info.supportedCapabilities.usb)
        assertEquals(789, info.supportedCapabilities.nfc)
        assertEquals("Tested Device", info.name)
        assertTrue(info.isNfc)
        assertNull(info.usbPid)
    }
}
