package com.yubico.authenticator.oath

import com.yubico.authenticator.device.Version
import com.yubico.authenticator.oath.OathTestHelper.code
import com.yubico.authenticator.oath.OathTestHelper.emptyCredentials
import com.yubico.authenticator.oath.OathTestHelper.hotp
import com.yubico.authenticator.oath.OathTestHelper.totp
import org.junit.Assert.*

import org.junit.Test

class ModelTest {

    private val model = Model()

    private fun connectDevice(deviceId: String) {
        model.session = Model.Session(
            deviceId,
            Version(1, 2, 3),
            isAccessKeySet = false,
            isRemembered = false,
            isLocked = false
        )
    }

    @Test
    fun `uses RFC 6238 values`() {
        assertEquals(0x10.toByte(), Model.OathType.HOTP.value)
        assertEquals(0x20.toByte(), Model.OathType.TOTP.value)
    }

    @Test
    fun `has no credentials after initialization`() {
        assertTrue(model.credentials.isEmpty())
    }

    @Test
    fun `updates empty model`() {

        val d = "device1"
        val m = mapOf(totp(d) to code())
        model.update(d, m)

        assertEquals(1, model.credentials.size)
    }

    @Test
    fun `replaces credentials on device change`() {
        val d1 = "device1"
        val m1 = mapOf(
            totp(d1) to code(),
            totp(d1) to code()
        )
        model.update(d1, m1)

        val d2 = "device2"
        val m2 = emptyCredentials()
        model.update(d2, m2)

        assertTrue(model.credentials.isEmpty())

        model.update(d1, m1)
        assertEquals(2, model.credentials.size)
    }

    @Test
    fun `preserves credentials on update`() {

        val d1 = "device1"

        val cred1 = totp(d1, name = "cred1")
        val cred2 = totp(d1, name = "cred2")
        val cred3 = totp(d1, name = "cred3")

        val m1 = mapOf(
            cred1 to code(),
            cred2 to code()
        )
        connectDevice(d1)
        model.update(d1, m1)

        // one more credential was added
        val m2 = mapOf(
            cred2 to code(),
            cred3 to code(),
            cred1 to code()
        )

        model.update(d1, m2)

        assertEquals("device1", model.session?.deviceId)
        assertEquals(3, model.credentials.size)
        assertTrue(model.credentials.find { it.credential == cred1 } != null)
        assertTrue(model.credentials.find { it.credential == cred2 } != null)
        assertTrue(model.credentials.find { it.credential == cred3 } != null)
    }

    @Test
    fun `updates credential codes`() {
        val cred = totp(name = "cred1")
        val code = code(value = "123456")
        val m1 = mapOf(cred to code)
        model.update(cred.deviceId, m1)

        assertTrue(model.credentials.find { it.code == code } != null)

        val updatedCode = code(value = "121212")
        val m2 = mapOf(cred to updatedCode)
        model.update(cred.deviceId, m2)

        assertTrue(model.credentials.find { it.code == updatedCode } != null)
    }

    @Test
    fun `update uses all credentials from its input `() {
        val d = "device"
        model.update(d, emptyCredentials())

        // in next update the device has credentials
        val totp1 = totp(deviceId = d, name = "totp1", touchRequired = false)
        val code1 = code(value = "111111")
        val totp2 = totp(deviceId = d, name = "totp2", touchRequired = true)
        val code2 = code(value = "222222")
        val hotp1 = hotp(deviceId = d, name = "hotp1", touchRequired = false)
        val code3 = code(value = "33333")
        val hotp2 = hotp(deviceId = d, name = "hotp2", touchRequired = true)
        val code4 = code(value = "4444")

        val m1 = mapOf(totp1 to code1, totp2 to code2, hotp1 to code3, hotp2 to code4)
        model.update(d, m1)

        // all four are present
        val foundTotp1 = model.credentials.find { it.credential == totp1 }
        assertTrue(foundTotp1 != null)
        assertEquals("111111", foundTotp1?.code?.value)

        val foundTotp2 = model.credentials.find { it.credential == totp2 }
        assertTrue(foundTotp2 != null)
        assertEquals("222222", foundTotp2?.code?.value)

        val foundHotp1 = model.credentials.find { it.credential == hotp1 }
        assertTrue(foundHotp1 != null)
        assertEquals("33333", foundHotp1?.code?.value)

        val foundHotp2 = model.credentials.find { it.credential == hotp2 }
        assertTrue(foundHotp2 != null)
        assertEquals("4444", foundHotp2?.code?.value)

    }

    @Test
    fun `update preserves non-interactive codes`() {
        val d = "device"
        val totp = totp(d, name = "totpCred")
        val totpCode: Model.Code? = null

        val hotp = hotp(d, name = "hotpCred")
        val hotpCode: Model.Code? = null

        val m1 = mapOf(hotp to hotpCode, totp to totpCode)
        model.update(d, m1)

        assertTrue(model.credentials.find { it.code == hotpCode } != null)

        val updatedTotpCode = code(value = "121212")
        val updatedHotpCode = code(value = "098765")
        val m2 = mapOf(hotp to updatedHotpCode, totp to updatedTotpCode)
        model.update(d, m2)

        assertTrue(model.credentials.find { it.code == updatedTotpCode } != null)
        assertTrue(model.credentials.find { it.code == hotpCode } != null)
        assertFalse(model.credentials.find { it.code == updatedHotpCode } != null)
    }

    @Test
    fun `update preserves interactive totp credentials`() {
        val d = "device"
        val totp = totp(d, name = "totpCred", touchRequired = true)
        val totpCode: Model.Code? = null

        connectDevice(d)
        model.update(d, mapOf(totp to totpCode))

        // simulate touch
        val newCode = model.updateCode(d, totp, code(value = "00000"))
        assertNotNull(newCode)

        // update with same values
        model.update(d, mapOf(totp to newCode))

        assertEquals(1, model.credentials.size)
        assertEquals("00000", model.credentials.find { it.credential == totp }?.code?.value)
    }

    @Test
    fun `adds new credentials`() {
        val d = "Device"
        val t1 = totp()
        val c1 = code()
        model.update(d, mapOf(t1 to c1))

        val t2 = totp()
        val c2 = code()
        val t3 = totp()
        val c3 = code()
        model.update(d, mapOf(t3 to c3, t2 to c2, t1 to c1))

        // t3 and t2 are added to credentials
        assertEquals(3, model.credentials.size)
    }

    @Test
    fun `removes non-existing credentials`() {
        val d = "Device"
        val t1 = totp()
        val c1 = code()
        val t2 = totp()
        val c2 = code()
        val t3 = totp()
        val c3 = code()

        model.update(d, mapOf(t3 to c3, t1 to c1, t2 to c2))
        assertEquals(3, model.credentials.size)

        model.update(d, mapOf(t1 to c1))

        // only t1 is part of credentials
        assertEquals(1, model.credentials.size)
        assertTrue(model.credentials.find { it.credential == t1 } != null)
    }

    @Test
    fun `adds one credential with code to empty`() {
        val d = "device"
        model.update(d, mapOf(totp() to code()))

        assertEquals(1, model.credentials.size)
    }

    @Test
    fun `does not add one credential with code to not initialized model`() {
        val d = "device"
        model.add(d, totp(), code())

        assertEquals(0, model.credentials.size)
    }

    @Test
    fun `adds credential only to correct device`() {
        val d1 = "device1"
        val d2 = "device2"
        connectDevice(d1)
        model.update(d1, mapOf(totp() to code()))

        // cannot add to this model
        assertNull(model.add(d2, totp(), code()))

        // can add to this model
        assertNotNull(model.add(d1, totp(), code()))

        assertEquals(2, model.credentials.size)
    }

    @Test
    fun `renames only on correct device`() {
        val d1 = "device1"
        val d2 = "device2"
        val toRename = totp(d1, name = "oldName", issuer = "oldIssuer")
        val code1 = code()

        connectDevice(d1)
        model.update(d1, mapOf(toRename to code1))

        val renamedForD2 = totp(d2, name = "newName", issuer = "newIssuer")
        assertNull(model.rename(d1, toRename, renamedForD2))

        val renamedForD1 = totp(d1, name = "newName", issuer = "newIssuer")
        // trying to rename on wrong device
        assertNull(model.rename(d2, toRename, renamedForD2))


        // rename success
        val renamed = model.rename(d1, toRename, renamedForD1)
        assertNotNull(renamed)

        // the name and issuer are correct
        assertEquals("newName", renamed?.accountName)
        assertEquals("newIssuer", renamed?.issuer)
    }

    @Test
    fun `renames issuer`() {
        val d = "device1"
        val toRename = totp(d, name = "oldName", issuer = "oldIssuer")
        val code1 = code()

        connectDevice(d)
        model.update(d, mapOf(toRename to code1))

        val nullIssuer = totp(d, name = "newName", issuer = null)
        val renamed = model.rename(d, toRename, nullIssuer)

        assertNull(renamed!!.issuer)

        val nonNullIssuer = totp(d, name = "newName", issuer = "valueHere")
        val renamed2 = model.rename(d, renamed, nonNullIssuer)

        assertNotNull(renamed2!!.issuer)
    }

    @Test
    fun `updates code`() {
        val d1 = "d1"
        val d2 = "d2"
        val totpD1 = totp(d1, name = "sameName", issuer = "sameIssuer")
        val totpD2 = totp(d2, name = "sameName", issuer = "sameIssuer")
        val code1 = code(value = "12345")
        val code2 = code(value = "00000")

        connectDevice(d1)
        model.update(d1, mapOf(totpD1 to code1))

        // cant update on different device
        assertNull(model.updateCode(d2, totpD1, code()))

        // cant update for credential from different device
        assertNull(model.updateCode(d1, totpD2, code()))

        // updates correctly to new code
        val newCode = model.updateCode(d1, totpD1, code2)
        assertNotNull(newCode)
        assertEquals("00000", newCode!!.value!!)
    }

    @Test
    fun `removes data on reset`() {
        val deviceId = "device"
        connectDevice(deviceId)
        model.update(deviceId, mapOf(totp() to code()))
        model.reset()

        assertNull(model.session)
        assertTrue(model.credentials.isEmpty())
    }
}