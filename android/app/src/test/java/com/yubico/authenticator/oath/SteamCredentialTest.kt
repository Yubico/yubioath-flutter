package com.yubico.authenticator.oath

import com.yubico.yubikit.oath.Credential
import com.yubico.yubikit.oath.OathSession
import com.yubico.yubikit.oath.OathType
import org.junit.Assert
import org.junit.Test
import org.mockito.Mockito.*

class SteamCredentialTest {

    @Test
    fun `recognize Steam credential`() {
        val c = mock(Credential::class.java)
        `when`(c.oathType).thenReturn(OathType.TOTP)
        `when`(c.issuer).thenReturn("Steam")
        Assert.assertTrue(c.isSteamCredential())

        `when`(c.oathType).thenReturn(OathType.HOTP)
        `when`(c.issuer).thenReturn("Steam")
        Assert.assertFalse(c.isSteamCredential())

        `when`(c.oathType).thenReturn(OathType.TOTP)
        `when`(c.issuer).thenReturn(null)
        Assert.assertFalse(c.isSteamCredential())
    }

    @Test(expected = IllegalArgumentException::class)
    fun `throw for non-Steam credential`() {
        val s = mock(OathSession::class.java)

        val c = mock(Credential::class.java)
        `when`(c.oathType).thenReturn(OathType.HOTP)
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
        mock(OathSession::class.java).also {
            `when`(
                it.calculateResponse(
                    isA(ByteArray::class.java),
                    isA(ByteArray::class.java)
                )
            ).thenReturn(response.fromHexString())
        }

    // valid Steam Credential mock
    private fun steamCredential() = mock(Credential::class.java).also {
        `when`(it.oathType).thenReturn(OathType.TOTP)
        `when`(it.issuer).thenReturn("Steam")
        `when`(it.id).thenReturn("id".toByteArray())
    }
}