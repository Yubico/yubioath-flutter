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

package com.yubico.authenticator.oath

import com.yubico.authenticator.oath.data.YubiKitCredential
import com.yubico.authenticator.oath.data.YubiKitOathSession
import com.yubico.authenticator.oath.data.YubiKitOathType
import com.yubico.authenticator.oath.data.calculateSteamCode
import com.yubico.authenticator.oath.data.isSteamCredential
import org.junit.Assert
import org.junit.Test
import org.mockito.Mockito.*

class SteamCredentialTest {

    @Test
    fun `recognize Steam credential`() {
        val c = mock(YubiKitCredential::class.java)
        `when`(c.oathType).thenReturn(YubiKitOathType.TOTP)
        `when`(c.issuer).thenReturn("Steam")
        Assert.assertTrue(c.isSteamCredential())

        `when`(c.oathType).thenReturn(YubiKitOathType.HOTP)
        `when`(c.issuer).thenReturn("Steam")
        Assert.assertFalse(c.isSteamCredential())

        `when`(c.oathType).thenReturn(YubiKitOathType.TOTP)
        `when`(c.issuer).thenReturn(null)
        Assert.assertFalse(c.isSteamCredential())
    }

    @Test(expected = IllegalArgumentException::class)
    fun `throw for non-Steam credential`() {
        val s = mock(YubiKitOathSession::class.java)

        val c = mock(YubiKitCredential::class.java)
        `when`(c.oathType).thenReturn(YubiKitOathType.HOTP)
        `when`(c.issuer).thenReturn("Steam")

        s.calculateSteamCode(c, 0)
    }

    @Test
    fun `calculate Steam code validity time slot`() {
        val s = sessionWith("6ad0d2d1674ad2a7c725c075901977f195bb4649")
        val c = steamCredential()

        val time = 100_000L

        val code = s.calculateSteamCode(c, time)

        Assert.assertEquals(90_000, code.validFrom)
        Assert.assertEquals(120_000, code.validUntil)
    }

    @Test
    fun `calculate Steam code`() {

        val c = steamCredential()

        Assert.assertEquals(
            "MV32B",
            sessionWith("6ad0d2d1674ad2a7c725c075901977f195bb4649")
                .calculateSteamCode(c, 0).value
        )
        Assert.assertEquals(
            "V8YBM",
            sessionWith("c5f852852f839924171b6cf6d272a1467bc62958")
                .calculateSteamCode(c, 0).value
        )
        Assert.assertEquals(
            "NN6VX",
            sessionWith("0a7053666137e5d2c8e96e0b2b52d5b1f3be1cf8")
                .calculateSteamCode(c, 0).value
        )
        Assert.assertEquals(
            "RB5N8",
            sessionWith("ed6d29417dfc8c0b800a1891181632802fd965c9")
                .calculateSteamCode(c, 0).value
        )
    }

    private fun String.fromHexString(): ByteArray = ByteArray(this.length / 2) {
        (this[it * 2 + 1].digitToInt(16) + (this[it * 2].digitToInt(16) * 16)).toByte()
    }

    // OathSession always calculating specific response
    private fun sessionWith(response: String) =
        mock(YubiKitOathSession::class.java).also {
            `when`(
                it.calculateResponse(
                    isA(ByteArray::class.java),
                    isA(ByteArray::class.java)
                )
            ).thenReturn(response.fromHexString())
        }

    // valid Steam Credential mock
    private fun steamCredential() = mock(YubiKitCredential::class.java).also {
        `when`(it.oathType).thenReturn(YubiKitOathType.TOTP)
        `when`(it.issuer).thenReturn("Steam")
        `when`(it.id).thenReturn("id".toByteArray())
    }
}