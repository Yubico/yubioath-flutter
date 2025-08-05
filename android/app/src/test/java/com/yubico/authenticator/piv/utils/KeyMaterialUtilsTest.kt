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

package com.yubico.authenticator.piv.utils

import com.yubico.authenticator.piv.utils.KeyMaterialTestData.Rsa2048
import org.junit.Assert
import org.junit.Test
import org.mockito.ArgumentMatchers.anyInt
import org.mockito.ArgumentMatchers.anyString
import org.mockito.Mockito.mockStatic
import java.security.interfaces.RSAPrivateKey
import java.util.Base64

class KeyMaterialUtilsTest {
    @Test
    fun `parse PKCS12 RSA2048`() {
        val (certs, key) = KeyMaterialUtils.parse(Rsa2048.PKCS12, "11234567")
        Assert.assertTrue(certs.size == 1)
        Assert.assertTrue(key is RSAPrivateKey)
    }

    @Test(expected = InvalidPasswordException::class)
    fun `parse PKCS12 RSA2048 without password`() {
        val (certs, key) = KeyMaterialUtils.parse(Rsa2048.PKCS12)
        Assert.assertTrue(certs.size == 1)
        Assert.assertTrue(key is RSAPrivateKey)
    }

    @Test(expected = InvalidPasswordException::class)
    fun `parse PKCS12 RSA2048 with wrong password`() {
        val (certs, key) = KeyMaterialUtils.parse(Rsa2048.PKCS12, "invalid")
        Assert.assertTrue(certs.size == 1)
        Assert.assertTrue(key is RSAPrivateKey)
    }


    @Test
    fun `parse PEM RSA2048`() {
        mockBase64 {
            val (certs, key) = KeyMaterialUtils.parse(Rsa2048.PEM)
            Assert.assertTrue(certs.size == 1)
            Assert.assertTrue(key is RSAPrivateKey)
        }
    }

    @Test
    fun `parse DER cert RSA2048`() {
        val (certs, key) = KeyMaterialUtils.parse(Rsa2048.DER_CERT)
        Assert.assertTrue(certs.size == 1)
        Assert.assertNull(key)
    }

    @Test
    fun `parse DER key RSA2048`() {
        val (certs, key) = KeyMaterialUtils.parse(Rsa2048.DER_KEY)
        Assert.assertTrue(certs.isEmpty())
        Assert.assertTrue(key is RSAPrivateKey)
    }

    companion object {
        fun mockBase64(block: () -> Unit) {
            mockStatic(android.util.Base64::class.java).use { mock ->

                mock.`when`<ByteArray> { android.util.Base64.decode(anyString(), anyInt()) }
                    .thenAnswer { invocation ->
                        Base64.getDecoder().decode(invocation.getArgument<String>(0))
                    }

                block()
            }
        }
    }
}