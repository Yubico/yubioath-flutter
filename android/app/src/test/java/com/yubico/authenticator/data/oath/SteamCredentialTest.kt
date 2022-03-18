package com.yubico.authenticator.data.oath

import com.yubico.yubikit.oath.Credential
import com.yubico.yubikit.oath.OathType
import org.junit.Assert
import org.junit.Test
import org.mockito.Mockito.`when`
import org.mockito.Mockito.mock

class SteamCredentialTest {

    @Test
    fun `recognize steam credential`() {
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
        val c = mock(Credential::class.java)
        `when`(c.oathType).thenReturn(OathType.HOTP)
        `when`(c.issuer).thenReturn("Steam")

        c.calculateSteamCode(0L) { _, _ ->
            byteArrayOf(0) // Code(byteArrayOf(0), 0, 0)
        }
    }

    @Test
    fun `code validity is correct`() {
        val c = mock(Credential::class.java)
        `when`(c.oathType).thenReturn(OathType.TOTP)
        `when`(c.issuer).thenReturn("Steam")
        `when`(c.accountName).thenReturn("accountName")
        `when`(c.id).thenReturn("id".toByteArray())
        `when`(c.period).thenReturn(30)

        val ms = 100_000L

        val code = c.calculateSteamCode(ms) { _, _ ->
            "6ad0d2d1674ad2a7c725c075901977f195bb4649".toByteArray()
        }

        Assert.assertEquals(90_000, code.validFrom)
        Assert.assertEquals(120_000, code.validUntil)
    }

    private fun String.fromHexString(): ByteArray = ByteArray(this.length / 2) {
        (this[it * 2 + 1].digitToInt(16) + (this[it * 2].digitToInt(16) * 16)).toByte()
    }

    @Test
    fun `code is correct`() {
        val c = mock(Credential::class.java)
        `when`(c.oathType).thenReturn(OathType.TOTP)
        `when`(c.issuer).thenReturn("Steam")
        `when`(c.accountName).thenReturn("accountName")
        `when`(c.id).thenReturn("id".toByteArray())
        `when`(c.period).thenReturn(30)

        Assert.assertEquals(
            "MV32B", c.calculateSteamCode(0L)
            { _, _ -> "6ad0d2d1674ad2a7c725c075901977f195bb4649".fromHexString() }.value
        )
        Assert.assertEquals(
            "V8YBM", c.calculateSteamCode(0L)
            { _, _ -> "c5f852852f839924171b6cf6d272a1467bc62958".fromHexString() }.value
        )
        Assert.assertEquals(
            "NN6VX", c.calculateSteamCode(0L)
            { _, _ -> "0a7053666137e5d2c8e96e0b2b52d5b1f3be1cf8".fromHexString() }.value
        )
        Assert.assertEquals(
            "RB5N8", c.calculateSteamCode(0L)
            { _, _ -> "ed6d29417dfc8c0b800a1891181632802fd965c9".fromHexString() }.value
        )
    }
}