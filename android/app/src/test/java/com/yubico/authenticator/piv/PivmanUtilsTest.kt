/*
 * Copyright (C) 2026 Yubico.
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

package com.yubico.authenticator.piv

import com.yubico.authenticator.device.Version
import com.yubico.authenticator.jsonSerializer
import com.yubico.authenticator.piv.data.PivState
import com.yubico.authenticator.piv.data.PivmanData
import com.yubico.authenticator.piv.data.PivmanProtectedData
import com.yubico.yubikit.core.util.Tlv
import com.yubico.yubikit.core.util.Tlvs
import com.yubico.yubikit.piv.ManagementKeyType
import com.yubico.yubikit.piv.ObjectId
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.mockito.ArgumentCaptor
import org.mockito.ArgumentMatchers.eq
import org.mockito.Mockito.mock
import org.mockito.Mockito.never
import org.mockito.Mockito.verify
import org.mockito.Mockito.verifyNoMoreInteractions
import org.mockito.Mockito.`when`

class PivmanUtilsTest {
    private fun metadata(vararg entries: Pair<Int, ByteArray>): ByteArray = Tlv(
        0x80,
        entries.fold(ByteArray(0)) { data, (tag, value) -> data + Tlv(tag, value).bytes }
    ).bytes

    @Test
    fun `only the stored key flag protects the management key`() {
        assertFalse(PivmanData().hasStoredKey)
        for (flags in listOf(0, 1, 2, 3)) {
            val data = PivmanData(
                metadata(0x81 to byteArrayOf(flags.toByte()), 0x82 to ByteArray(16) { 1 })
            )
            assertEquals(flags and 2 != 0, data.hasStoredKey)
        }
        assertFalse(PivmanData(metadata(0x82 to ByteArray(16) { 1 })).hasStoredKey)
    }

    @Test
    fun `changing key protection preserves opaque metadata and unrelated flags`() {
        val opaque = ByteArray(16) { 1 }
        val data = PivmanData(
            metadata(0x81 to byteArrayOf(1), 0x82 to opaque, 0x84 to byteArrayOf(42))
        )
        for (storeKey in listOf(true, false)) {
            data.mgmKeyProtected = storeKey
            assertEquals(storeKey, data.hasStoredKey)
            assertTrue(data.pukBlocked)
            val entries = Tlvs.decodeMap(Tlv.parse(data.getBytes()).value)
            assertArrayEquals(opaque, entries[0x82])
            assertArrayEquals(byteArrayOf(42), entries[0x84])
            assertArrayEquals(byteArrayOf(if (storeKey) 3 else 1), entries[0x81])
        }
    }

    @Test
    fun `changing an unprotected management key does not rewrite opaque metadata`() {
        val piv = mock(YubiKitPivSession::class.java)
        val key = ByteArray(24) { 1 }
        `when`(piv.getObject(ObjectId.PIVMAN_DATA))
            .thenReturn(metadata(0x82 to ByteArray(16) { 1 }))

        PivmanUtils.pivmanSetMgmKey(piv, key, ManagementKeyType.TDES)

        verify(piv).getObject(ObjectId.PIVMAN_DATA)
        verify(piv).setManagementKey(ManagementKeyType.TDES, key, false)
        verify(piv, never()).getObject(ObjectId.PIVMAN_PROTECTED_DATA)
        verifyNoMoreInteractions(piv)
    }

    @Test
    fun `storing a management key sets protection and preserves opaque metadata`() {
        val piv = mock(YubiKitPivSession::class.java)
        val key = ByteArray(24) { 1 }
        val opaque = ByteArray(16) { 2 }
        `when`(piv.getObject(ObjectId.PIVMAN_DATA))
            .thenReturn(metadata(0x81 to byteArrayOf(1), 0x82 to opaque))
        `when`(piv.getObject(ObjectId.PIVMAN_PROTECTED_DATA))
            .thenReturn(Tlv(0x88, null).bytes)

        PivmanUtils.pivmanSetMgmKey(piv, key, ManagementKeyType.TDES, storeOnDevice = true)

        verify(piv).setManagementKey(ManagementKeyType.TDES, key, false)
        val written = ArgumentCaptor.forClass(ByteArray::class.java)
        verify(piv).putObject(eq(ObjectId.PIVMAN_DATA), written.capture())
        val publicData = PivmanData(written.value)
        assertTrue(publicData.hasStoredKey)
        assertTrue(publicData.pukBlocked)
        assertArrayEquals(opaque, Tlvs.decodeMap(Tlv.parse(written.value).value)[0x82])
        verify(piv).putObject(eq(ObjectId.PIVMAN_PROTECTED_DATA), written.capture())
        assertArrayEquals(key, PivmanProtectedData(written.value).key)
    }

    @Test
    fun `serialized PIV state contains only stored key protection`() {
        for (storedKey in listOf(false, true)) {
            val state = PivState(
                version = Version(5, 7, 0),
                authenticated = false,
                storedKey = storedKey,
                pinAttempts = 3,
                supportsBio = false,
                chuid = null,
                ccc = null,
                metadata = null
            )
            val json = jsonSerializer.parseToJsonElement(state.toJson()).jsonObject
            assertEquals(
                setOf(
                    "version",
                    "authenticated",
                    "stored_key",
                    "pin_attempts",
                    "supports_bio",
                    "chuid",
                    "ccc",
                    "metadata"
                ),
                json.keys
            )
            assertEquals(JsonPrimitive(storedKey), json["stored_key"])
        }
    }
}
