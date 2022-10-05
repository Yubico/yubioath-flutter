package com.yubico.authenticator.yubikit

import android.hardware.usb.UsbDevice
import android.os.Build
import com.yubico.authenticator.TestUtil
import com.yubico.authenticator.device.Version
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.UsbPid
import org.junit.Assert.*
import org.junit.Test
import org.mockito.Mockito.`when`
import org.mockito.Mockito.mock


class SkyHelperTest {

    init {
        // TODO: test lower APIs
        TestUtil.setFinalStatic(Build.VERSION::class.java.getField("SDK_INT"), 23)
    }

    @Test
    fun `passing NfcYubiKeyDevice will throw`() {
        assertThrows(IllegalArgumentException::class.java) {
            SkyHelper.getDeviceInfo(mock(NfcYubiKeyDevice::class.java))
        }
    }

    @Test
    fun `supports three specific UsbPids`() {
        for (pid in UsbPid.values()) {
            val ykDevice = getUsbYubiKeyDeviceMock().also {
                `when`(it.pid).thenReturn(pid)
            }

            if (pid in listOf(UsbPid.YK4_FIDO, UsbPid.SKY_FIDO, UsbPid.NEO_FIDO)) {
                // these will not throw
                assertNotNull(SkyHelper.getDeviceInfo(ykDevice))
            } else {
                // all other will throw
                assertThrows(IllegalArgumentException::class.java) {
                    SkyHelper.getDeviceInfo(ykDevice)
                }
            }
        }
    }

    @Test
    fun `handles NEO_FIDO versions`() {
        val ykDevice = getUsbYubiKeyDeviceMock().also {
            `when`(it.pid).thenReturn(UsbPid.NEO_FIDO)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("3.00")
        SkyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(Version(3, 0, 0), it.version)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("3.47")
        SkyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(Version(3, 4, 7), it.version)
        }

        // lower than 3 should return 0.0.0
        `when`(ykDevice.usbDevice.version).thenReturn("2.10")
        SkyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(VERSION_0, it.version)
        }

        // greater or equal 4.0.0 should return 0.0.0
        `when`(ykDevice.usbDevice.version).thenReturn("4.00")
        SkyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(VERSION_0, it.version)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("4.37")
        SkyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(VERSION_0, it.version)
        }
    }

    @Test
    fun `handles SKY_FIDO versions`() {
        val ykDevice = getUsbYubiKeyDeviceMock().also {
            `when`(it.pid).thenReturn(UsbPid.SKY_FIDO)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("3.00")
        SkyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(Version(3, 0, 0), it.version)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("3.47")
        SkyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(Version(3, 4, 7), it.version)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("4.00")
        SkyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(Version(4, 0, 0), it.version)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("4.37")
        SkyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(Version(4, 3, 7), it.version)
        }

        // lower than 3 should return 0.0.0
        `when`(ykDevice.usbDevice.version).thenReturn("2.10")
        SkyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(VERSION_0, it.version)
        }

    }

    @Test
    fun `handles YK4_FIDO versions`() {
        val ykDevice = getUsbYubiKeyDeviceMock().also {
            `when`(it.pid).thenReturn(UsbPid.YK4_FIDO)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("4.00")
        SkyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(Version(4, 0, 0), it.version)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("4.37")
        SkyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(Version(4, 3, 7), it.version)
        }

        // lower than 4 should return 0.0.0
        `when`(ykDevice.usbDevice.version).thenReturn("3.47")
        SkyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(VERSION_0, it.version)
        }
    }

    @Test
    fun `returns Version 0 for invalid input`() {
        val ykDevice = getUsbYubiKeyDeviceMock().also {
            `when`(it.pid).thenReturn(UsbPid.SKY_FIDO)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("")
        SkyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(VERSION_0, it.version)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("yubico")
        SkyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(VERSION_0, it.version)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("4")
        SkyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(VERSION_0, it.version)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("4.")
        SkyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(VERSION_0, it.version)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("4.0")
        SkyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(VERSION_0, it.version)
        }

        `when`(ykDevice.usbDevice.version).thenReturn("4.0.0")
        SkyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(VERSION_0, it.version)
        }

    }

    @Test
    fun `returns default product name`() {
        val ykDevice = getUsbYubiKeyDeviceMock()
        `when`(ykDevice.pid).thenReturn(UsbPid.SKY_FIDO)
        `when`(ykDevice.usbDevice.version).thenReturn("5.50")
        `when`(ykDevice.usbDevice.productName).thenReturn(null)

        SkyHelper.getDeviceInfo(ykDevice).also {
            assertEquals(it.name, "YubiKey Security Key")
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