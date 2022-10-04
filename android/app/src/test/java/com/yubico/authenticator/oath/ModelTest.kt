/*
 * Copyright (C) 2022 Yubico.
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

package com.yubico.authenticator.oath

import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import com.yubico.authenticator.device.Version
import com.yubico.authenticator.oath.OathTestHelper.code
import com.yubico.authenticator.oath.OathTestHelper.emptyCredentials
import com.yubico.authenticator.oath.OathTestHelper.hotp
import com.yubico.authenticator.oath.OathTestHelper.totp
import org.junit.Assert.*
import org.junit.Rule

import org.junit.Test

class ModelTest {

    @get:Rule
    val rule = InstantTaskExecutorRule()

    private val viewModel = OathViewModel()

    private fun connectDevice(deviceId: String) {
        viewModel.setSessionState(Model.Session(
            deviceId,
            Version(1, 2, 3),
            isAccessKeySet = false,
            isRemembered = false,
            isLocked = false
        ))
    }

    @Test
    fun `uses RFC 6238 values`() {
        assertEquals(0x10.toByte(), Model.OathType.HOTP.value)
        assertEquals(0x20.toByte(), Model.OathType.TOTP.value)
    }

    @Test
    fun `has no credentials after initialization`() {
        assertNull(viewModel.credentials.value)
    }

    @Test
    fun `updates empty model`() {
        val d = "device1"
        connectDevice(d)
        val m = mapOf(totp(d) to code())
        viewModel.updateCredentials(m)

        assertEquals(1, viewModel.credentials.value?.size)
    }

    @Test
    fun `replaces credentials on device change`() {
        val d1 = "device1"
        connectDevice(d1)
        val m1 = mapOf(
            totp(d1) to code(),
            totp(d1) to code()
        )
        viewModel.updateCredentials(m1)

        connectDevice("device2")
        val m2 = emptyCredentials()
        viewModel.updateCredentials(m2)

        assertTrue(viewModel.credentials.value!!.isEmpty())

        connectDevice("device1")
        viewModel.updateCredentials(m1)
        assertEquals(2, viewModel.credentials.value!!.size)
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
        viewModel.updateCredentials(m1)

        // one more credential was added
        val m2 = mapOf(
            cred2 to code(),
            cred3 to code(),
            cred1 to code()
        )

        viewModel.updateCredentials(m2)

        assertEquals("device1", viewModel.sessionState.value?.deviceId)
        assertEquals(3, viewModel.credentials.value!!.size)
        assertTrue(viewModel.credentials.value!!.find { it.credential == cred1 } != null)
        assertTrue(viewModel.credentials.value!!.find { it.credential == cred2 } != null)
        assertTrue(viewModel.credentials.value!!.find { it.credential == cred3 } != null)
    }

    @Test
    fun `updates credential codes`() {
        val cred = totp(name = "cred1")
        val code = code(value = "123456")
        val m1 = mapOf(cred to code)

        connectDevice(cred.deviceId)
        viewModel.updateCredentials(m1)

        assertTrue(viewModel.credentials.value?.find { it.code == code } != null)

        val updatedCode = code(value = "121212")
        val m2 = mapOf(cred to updatedCode)
        viewModel.updateCredentials(m2)

        assertTrue(viewModel.credentials.value?.find { it.code == updatedCode } != null)
    }

    @Test
    fun `update uses all credentials from its input `() {
        val d = "device"
        connectDevice(d)
        viewModel.updateCredentials(emptyCredentials())

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
        viewModel.updateCredentials(m1)

        // all four are present
        val foundTotp1 = viewModel.credentials.value?.find { it.credential == totp1 }
        assertTrue(foundTotp1 != null)
        assertEquals("111111", foundTotp1?.code?.value)

        val foundTotp2 = viewModel.credentials.value?.find { it.credential == totp2 }
        assertTrue(foundTotp2 != null)
        assertEquals("222222", foundTotp2?.code?.value)

        val foundHotp1 = viewModel.credentials.value?.find { it.credential == hotp1 }
        assertTrue(foundHotp1 != null)
        assertEquals("33333", foundHotp1?.code?.value)

        val foundHotp2 = viewModel.credentials.value?.find { it.credential == hotp2 }
        assertTrue(foundHotp2 != null)
        assertEquals("4444", foundHotp2?.code?.value)

    }

    @Test
    fun `update without code preserves existing value`() {
        val d = "device"
        val totp = totp(d, name = "totpCred")
        val totpCode: Model.Code? = null

        val hotp = hotp(d, name = "hotpCred")
        val hotpCode: Model.Code? = code(value = "098765")

        val m1 = mapOf(hotp to hotpCode, totp to totpCode)

        connectDevice(d)
        viewModel.updateCredentials(m1)

        assertTrue(viewModel.credentials.value?.find { it.code == hotpCode } != null)

        val updatedTotpCode = code(value = "121212")
        val updatedHotpCode = null
        val m2 = mapOf(hotp to updatedHotpCode, totp to updatedTotpCode)
        viewModel.updateCredentials(m2)

        assertTrue(viewModel.credentials.value?.find { it.code == updatedTotpCode } != null)
        assertTrue(viewModel.credentials.value?.find { it.code == hotpCode } != null)
        assertFalse(viewModel.credentials.value?.find { it.code == updatedHotpCode } != null)
    }

    @Test
    fun `update preserves interactive totp credentials`() {
        val d = "device"
        val totp = totp(d, name = "totpCred", touchRequired = true)
        val totpCode: Model.Code? = null

        connectDevice(d)
        viewModel.updateCredentials(mapOf(totp to totpCode))

        // simulate touch
        viewModel.updateCode(totp, code(value = "00000"))
        val newCode = viewModel.credentials.value?.find { it.credential == totp }?.code
        assertNotNull(newCode)

        // update with same values
        viewModel.updateCredentials(mapOf(totp to newCode))

        assertEquals(1, viewModel.credentials.value?.size)
        assertEquals("00000", viewModel.credentials.value?.find { it.credential == totp }?.code?.value)
    }

    @Test
    fun `adds new credentials`() {
        val d = "Device"
        val t1 = totp()
        val c1 = code()
        connectDevice(d)
        viewModel.updateCredentials(mapOf(t1 to c1))

        val t2 = totp()
        val c2 = code()
        val t3 = totp()
        val c3 = code()
        viewModel.updateCredentials(mapOf(t3 to c3, t2 to c2, t1 to c1))

        // t3 and t2 are added to credentials
        assertEquals(3, viewModel.credentials.value?.size)
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

        connectDevice(d)
        viewModel.updateCredentials(mapOf(t3 to c3, t1 to c1, t2 to c2))
        assertEquals(3, viewModel.credentials.value?.size)

        viewModel.updateCredentials(mapOf(t1 to c1))

        // only t1 is part of credentials
        assertEquals(1, viewModel.credentials.value?.size)
        assertTrue(viewModel.credentials.value?.find { it.credential == t1 } != null)
    }

    @Test
    fun `adds one credential with code to empty`() {
        val d = "device"
        connectDevice(d)
        viewModel.updateCredentials(mapOf(totp() to code()))

        assertEquals(1, viewModel.credentials.value?.size)
    }

    @Test
    fun `does not add one credential with code to not initialized model`() {
        val d = "device"
        connectDevice(d)
        assertThrows(IllegalArgumentException::class.java) {
            viewModel.addCredential(totp(), code())
        }

        assertEquals(0, viewModel.credentials.value?.size ?: 0)
    }

    @Test
    fun `adds credential only to correct device`() {
        val d1 = "device1"
        val d2 = "device2"
        connectDevice(d1)
        viewModel.updateCredentials(mapOf(totp(d1) to code()))

        // cannot add to this model
        assertThrows(IllegalArgumentException::class.java) {
            viewModel.addCredential(totp(), code())
        }

        // can add to this model
        assertNotNull(viewModel.addCredential(totp(d1), code()))

        assertEquals(2, viewModel.credentials.value?.size)
    }

    @Test
    fun `renames only on correct device`() {
        val d1 = "device1"
        val d2 = "device2"
        val toRename = totp(d1, name = "oldName", issuer = "oldIssuer")
        val code1 = code()

        connectDevice(d1)
        viewModel.updateCredentials(mapOf(toRename to code1))

        val renamedForD2 = totp(d2, name = "newName", issuer = "newIssuer")
        assertThrows(IllegalArgumentException::class.java) {
            viewModel.renameCredential(toRename, renamedForD2)
        }

        val renamedForD1 = totp(d1, name = "newName", issuer = "newIssuer")
        // trying to rename on wrong device
        assertThrows(IllegalArgumentException::class.java) {
            viewModel.renameCredential(toRename, renamedForD2)
        }


        // rename success
        viewModel.renameCredential(toRename, renamedForD1)
        val renamed = viewModel.credentials.value?.find { it.credential == renamedForD1 }?.credential
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
        viewModel.updateCredentials(mapOf(toRename to code1))

        val nullIssuer = totp(d, name = "newName", issuer = null)
        viewModel.renameCredential(toRename, nullIssuer)
        val renamed = viewModel.credentials.value?.find { it.credential == nullIssuer }?.credential

        assertNull(renamed!!.issuer)

        val nonNullIssuer = totp(d, name = "newName", issuer = "valueHere")
        viewModel.renameCredential(nullIssuer, nonNullIssuer)
        val renamed2 = viewModel.credentials.value?.find { it.credential == nonNullIssuer }?.credential

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
        viewModel.updateCredentials(mapOf(totpD1 to code1))

        // cant update for credential from different device
        // TODO: This should fail
        assertThrows(NullPointerException::class.java) {
            viewModel.updateCode(totpD2, code())
        }

        // updates correctly to new code
        viewModel.updateCode(totpD1, code2)
        val newCode = viewModel.credentials.value?.find { it.credential == totpD1 }?.code
        assertNotNull(newCode)
        assertEquals("00000", newCode!!.value!!)
    }

    @Test
    fun `removes data on reset`() {
        val deviceId = "device"
        connectDevice(deviceId)
        viewModel.updateCredentials(mapOf(totp() to code()))
        viewModel.setSessionState(null)

        assertNull(viewModel.sessionState.value)
        assertNull(viewModel.credentials.value)
    }
}