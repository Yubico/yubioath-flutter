/*
 * Copyright (C) 2025 Yubico.
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

import android.util.Base64
import com.yubico.authenticator.piv.TestData.ECCP384
import com.yubico.authenticator.piv.TestData.ED25519
import com.yubico.authenticator.piv.TestData.RSA2048
import com.yubico.authenticator.piv.TestData.X25519
import org.bouncycastle.jcajce.interfaces.EdDSAPrivateKey
import org.bouncycastle.jce.interfaces.ECPrivateKey
import org.bouncycastle.jce.provider.BouncyCastleProvider
import org.junit.Assert
import org.junit.Before
import org.junit.Test
import org.mockito.ArgumentMatchers
import org.mockito.Mockito
import java.security.Security
import java.security.interfaces.RSAPrivateKey
import java.security.interfaces.XECPrivateKey

class KeyMaterialParserTest {

    @Before
    fun `setup BC`() {
        Security.removeProvider("BC")
        Security.insertProviderAt(BouncyCastleProvider(), 1)
    }

    @Test
    fun `rsa2048 p12`() {
        val (certs, key) = KeyMaterialParser.parse(RSA2048.PKCS12, password())
        Assert.assertTrue(certs.size == 1)
        Assert.assertTrue(key is RSAPrivateKey)
    }

    @Test(expected = InvalidPasswordException::class)
    fun `rsa2048 p12 no password`() {
        val (certs, key) = KeyMaterialParser.parse(RSA2048.PKCS12)
        Assert.assertTrue(certs.size == 1)
        Assert.assertTrue(key is RSAPrivateKey)
    }

    @Test(expected = InvalidPasswordException::class)
    fun `rsa2048 p12 wrong password`() {
        val (certs, key) = KeyMaterialParser.parse(RSA2048.PKCS12, invalidPassword())
        Assert.assertTrue(certs.size == 1)
        Assert.assertTrue(key is RSAPrivateKey)
    }

    @Test
    fun `rsa2048 pem`() {
        mockBase64 {
            val (certs, key) = KeyMaterialParser.parse(RSA2048.PEM, password())
            Assert.assertTrue(certs.size == 1)
            Assert.assertTrue(key is RSAPrivateKey)
        }
    }

    @Test
    fun `rsa2048 enc pem`() {
        mockBase64 {
            val (certs, key) = KeyMaterialParser.parse(RSA2048.PEM_ENC, password())
            Assert.assertTrue(certs.size == 1)
            Assert.assertTrue(key is RSAPrivateKey)
        }
    }

    @Test
    fun `rsa2048 crt der`() {
        val (certs, key) = KeyMaterialParser.parse(RSA2048.DER_CERT)
        Assert.assertTrue(certs.size == 1)
        Assert.assertNull(key)
    }

    @Test
    fun `rsa2048 key der`() {
        val (certs, key) = KeyMaterialParser.parse(RSA2048.DER_KEY)
        Assert.assertTrue(certs.isEmpty())
        Assert.assertTrue(key is RSAPrivateKey)
    }

    // X25519
    @Test
    fun `X25519 key pem`() {
        mockBase64 {
            val (certs, key) = KeyMaterialParser.parse(X25519.PEM)
            Assert.assertTrue(certs.isEmpty())
            Assert.assertTrue(key is XECPrivateKey)
        }
    }

    @Test
    fun `X25519 key enc pem`() {
        mockBase64 {
            val (certs, key) = KeyMaterialParser.parse(X25519.PEM_ENC, password())
            Assert.assertTrue(certs.isEmpty())
            Assert.assertTrue(key is XECPrivateKey)
        }
    }

    @Test
    fun `X25519 key der`() {
        val (certs, key) = KeyMaterialParser.parse(X25519.DER)
        Assert.assertTrue(certs.isEmpty())
        Assert.assertTrue(key is XECPrivateKey)
    }

    // Ed25519
    @Test
    fun `Ed25519 key pem`() {
        mockBase64 {
            val (certs, key) = KeyMaterialParser.parse(ED25519.PEM)
            Assert.assertEquals(1, certs.size)
            Assert.assertTrue(key is EdDSAPrivateKey)
        }
    }

    @Test
    fun `Ed25519 key enc pem`() {
        mockBase64 {
            val (certs, key) = KeyMaterialParser.parse(ED25519.PEM_ENC, password())
            Assert.assertEquals(1, certs.size)
            Assert.assertTrue(key is EdDSAPrivateKey)
        }
    }

    @Test
    fun `Ed25519 key der`() {
        val (certs, key) = KeyMaterialParser.parse(ED25519.DER_KEY)
        Assert.assertTrue(certs.isEmpty())
        Assert.assertTrue(key is EdDSAPrivateKey)
    }

    @Test
    fun `Ed25519 crt der`() {
        val (certs, key) = KeyMaterialParser.parse(ED25519.DER_CERT)
        Assert.assertEquals(1, certs.size)
        Assert.assertNull(key)
    }

    @Test
    fun `Ed25519 p12`() {
        val (certs, key) = KeyMaterialParser.parse(ED25519.PKCS12, password())
        Assert.assertEquals(1, certs.size)
        Assert.assertTrue(key is EdDSAPrivateKey)
    }

    // ECCP384
    @Test
    fun `ecsecp384r1 pem`() {
        mockBase64 {
            val (certs, key) = KeyMaterialParser.parse(ECCP384.PEM)
            Assert.assertEquals(1, certs.size)
            Assert.assertTrue(key is ECPrivateKey)
        }
    }

    @Test
    fun `ecsecp384r1 enc pem`() {
        mockBase64 {
            val (certs, key) = KeyMaterialParser.parse(ECCP384.PEM_ENC, password())
            Assert.assertEquals(1, certs.size)
            Assert.assertTrue(key is ECPrivateKey)
        }
    }

    @Test
    fun `ecsecp384r1 key`() {
        val (certs, key) = KeyMaterialParser.parse(ECCP384.DER_KEY)
        Assert.assertTrue(certs.isEmpty())
        Assert.assertTrue(key is ECPrivateKey)
    }

    @Test
    fun `ecsecp384r1 crt der`() {
        val (certs, key) = KeyMaterialParser.parse(ECCP384.DER_CERT)
        Assert.assertEquals(1, certs.size)
        Assert.assertNull(key)
    }

    @Test
    fun `ecsecp384r1 p12`() {
        val (certs, key) = KeyMaterialParser.parse(ECCP384.PKCS12, password())
        Assert.assertEquals(1, certs.size)
        Assert.assertTrue(key is ECPrivateKey)
    }

    companion object {
        fun password() = "11234567".toCharArray()
        fun invalidPassword() = "1123456".toCharArray()
        fun mockBase64(block: () -> Unit) {
            Mockito.mockStatic(Base64::class.java).use { mock ->

                mock.`when`<ByteArray> {
                    Base64.decode(
                        ArgumentMatchers.anyString(),
                        ArgumentMatchers.anyInt()
                    )
                }
                    .thenAnswer { invocation ->
                        java.util.Base64.getDecoder().decode(invocation.getArgument<String>(0))
                    }

                block()
            }
        }
    }
}