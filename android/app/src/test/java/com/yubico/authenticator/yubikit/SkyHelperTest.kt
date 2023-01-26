/*
 * Copyright (C) 2022-2023 Yubico.
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

package com.yubico.authenticator.yubikit

import android.hardware.usb.UsbDevice
import com.yubico.authenticator.CompatUtil
import com.yubico.authenticator.device.Version
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.UsbPid
import org.junit.Assert.*
import org.junit.Test
import org.mockito.Mockito.mock
import org.mockito.Mockito.`when`

class SkyHelperTest {

    @Test
    fun `passing NfcYubiKeyDevice will throw`() {
        val skyHelper = SkyHelper(CompatUtil(33))

        assertThrows(IllegalArgumentException::class.java) {
            skyHelper.getDeviceInfo(mock(NfcYubiKeyDevice::class.java))
        }
    }

    @Test
    fun `supports three specific UsbPids`() {
        val skyHelper = SkyHelper(CompatUtil(33))

        for (pid in UsbPid.values()) {
            val ykDevice = getUsbYubiKeyDeviceMock().also {
                `when`(it.pid).thenReturn(pid)
            }

            if (pid in listOf(UsbPid.YK4_FIDO, UsbPid.SKY_FIDO, UsbPid.NEO_FIDO)) {
                // these will not throw
                assertNotNull(skyHelper.getDeviceInfo(ykDevice))
            } else {
                // all other will throw
                assertThrows(IllegalArgumentException::class.java) {
                    skyHelper.getDeviceInfo(ykDevice)
                }
            }
        }
    }

    @Test
    fun `handles NEO_FIDO versions`() {

        val skyHelper = SkyHelper(CompatUtil(23))

        val ykDevice = getUsbYubiKeyDeviceMock().also {
            `when`(it.pid).thenReturn(UsbPid.NEO_FIDO)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("3.00")
        skyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(Version(3, 0, 0), it.version)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("3.47")
        skyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(Version(3, 4, 7), it.version)
        }

        // lower than 3 should return 0.0.0
        `when`(ykDevice.usbDevice.version).thenReturn("2.10")
        skyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(VERSION_0, it.version)
        }

        // greater or equal 4.0.0 should return 0.0.0
        `when`(ykDevice.usbDevice.version).thenReturn("4.00")
        skyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(VERSION_0, it.version)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("4.37")
        skyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(VERSION_0, it.version)
        }
    }

    @Test
    fun `handles SKY_FIDO versions`() {

        val skyHelper = SkyHelper(CompatUtil(23))

        val ykDevice = getUsbYubiKeyDeviceMock().also {
            `when`(it.pid).thenReturn(UsbPid.SKY_FIDO)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("3.00")
        skyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(Version(3, 0, 0), it.version)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("3.47")
        skyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(Version(3, 4, 7), it.version)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("4.00")
        skyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(Version(4, 0, 0), it.version)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("4.37")
        skyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(Version(4, 3, 7), it.version)
        }

        // lower than 3 should return 0.0.0
        `when`(ykDevice.usbDevice.version).thenReturn("2.10")
        skyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(VERSION_0, it.version)
        }

    }

    @Test
    fun `handles YK4_FIDO versions`() {

        val skyHelper = SkyHelper(CompatUtil(23))

        val ykDevice = getUsbYubiKeyDeviceMock().also {
            `when`(it.pid).thenReturn(UsbPid.YK4_FIDO)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("4.00")
        skyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(Version(4, 0, 0), it.version)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("4.37")
        skyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(Version(4, 3, 7), it.version)
        }

        // lower than 4 should return 0.0.0
        `when`(ykDevice.usbDevice.version).thenReturn("3.47")
        skyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(VERSION_0, it.version)
        }
    }
    @Test
    fun `returns VERSION_0 for older APIs`() {

        // below API 23, there is no UsbDevice.version
        // therefore we expect deviceInfo to have VERSION_0
        // for every FIDO key
        val skyHelper = SkyHelper(CompatUtil(22))

        val neoFidoDevice = getUsbYubiKeyDeviceMock().also {
            `when`(it.pid).thenReturn(UsbPid.NEO_FIDO)
        }

        `when`(neoFidoDevice.usbDevice.version).thenReturn("3.47") // valid NEO_FIDO version
        skyHelper.getDeviceInfo(neoFidoDevice).also {
            assertEquals(VERSION_0, it.version)
        }

        val skyFidoDevice = getUsbYubiKeyDeviceMock().also {
            `when`(it.pid).thenReturn(UsbPid.SKY_FIDO)
        }

        `when`(skyFidoDevice.usbDevice.version).thenReturn("3.47") // valid SKY_FIDO version
        skyHelper.getDeviceInfo(skyFidoDevice).also {
            assertEquals(VERSION_0, it.version)
        }

        val yk4FidoDevice = getUsbYubiKeyDeviceMock().also {
            `when`(it.pid).thenReturn(UsbPid.YK4_FIDO)
        }

        `when`(yk4FidoDevice.usbDevice.version).thenReturn("4.37") // valid YK4_FIDO version
        skyHelper.getDeviceInfo(yk4FidoDevice).also {
            assertEquals(VERSION_0, it.version)
        }
    }
    @Test
    fun `returns VERSION_0 for invalid input`() {
        val skyHelper = SkyHelper(CompatUtil(33))

        val ykDevice = getUsbYubiKeyDeviceMock().also {
            `when`(it.pid).thenReturn(UsbPid.SKY_FIDO)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("")
        skyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(VERSION_0, it.version)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("yubico")
        skyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(VERSION_0, it.version)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("4")
        skyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(VERSION_0, it.version)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("4.")
        skyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(VERSION_0, it.version)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("4.0")
        skyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(VERSION_0, it.version)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("4.0.0")
        skyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(VERSION_0, it.version)
        }

    }

    @Test
    fun `returns default product name`() {
        val skyHelper = SkyHelper(CompatUtil(33))

        val ykDevice = getUsbYubiKeyDeviceMock()
        `when`(ykDevice.pid).thenReturn(UsbPid.SKY_FIDO)
        `when`(ykDevice.usbDevice.version).thenReturn("5.50")
        `when`(ykDevice.usbDevice.productName).thenReturn(null)

        skyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(it.name, "Yubico Security Key")
        }
    }

    companion object {
        fun getUsbYubiKeyDeviceMock(): UsbYubiKeyDevice = mock(UsbYubiKeyDevice::class.java).also {
            `when`(it.pid).thenReturn(UsbPid.YKS_OTP)
            `when`(it.usbDevice).thenReturn(mock(UsbDevice::class.java))
            `when`(it.usbDevice.productName).thenReturn("")
            `when`(it.usbDevice.version).thenReturn("")
        }

        private val VERSION_0 = Version(0, 0, 0)
    }

}