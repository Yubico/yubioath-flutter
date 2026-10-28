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

import com.yubico.yubikit.piv.PivSession
import com.yubico.yubikit.piv.Slot
import java.security.KeyPairGenerator
import java.security.PublicKey
import java.security.Security
import org.bouncycastle.asn1.nist.NISTObjectIdentifiers
import org.bouncycastle.jce.provider.BouncyCastleProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test
import org.mockito.Mockito

class CertificateUtilsTest {

    @Before
    fun `setup BC`() {
        Security.removeProvider("BC")
        Security.insertProviderAt(BouncyCastleProvider(), 1)
    }

    private fun publicKey(algorithm: String): PublicKey =
        KeyPairGenerator.getInstance(algorithm, "BC").generateKeyPair().public

    @Test
    fun `ml-dsa public keys are detected`() {
        listOf("ML-DSA-44", "ML-DSA-65", "ML-DSA-87").forEach {
            assertEquals(it, KeyAlgorithm.MLDSA, KeyAlgorithm.fromPublicKey(publicKey(it)))
        }
    }

    @Test
    fun `ml-dsa signature algorithm uses the parameter set oid`() {
        mapOf(
            "ML-DSA-44" to NISTObjectIdentifiers.id_ml_dsa_44,
            "ML-DSA-65" to NISTObjectIdentifiers.id_ml_dsa_65,
            "ML-DSA-87" to NISTObjectIdentifiers.id_ml_dsa_87
        ).forEach { (name, oid) ->
            val algorithm = resolveSignatureAlgorithm(publicKey(name), HashAlgorithm.SHA256)

            assertEquals(name, "ML-DSA", algorithm.jcaName)
            assertEquals(name, oid, algorithm.fixedAlgId)
        }
    }

    @Test
    fun `content signer reports the ml-dsa algorithm identifier`() {
        val algorithm = resolveSignatureAlgorithm(publicKey("ML-DSA-65"), HashAlgorithm.SHA256)

        val signer =
            PivContentSigner(Mockito.mock(PivSession::class.java), Slot.SIGNATURE, algorithm)

        assertEquals(NISTObjectIdentifiers.id_ml_dsa_65, signer.algorithmIdentifier.algorithm)
        assertNull(signer.algorithmIdentifier.parameters)
    }

    @Test(expected = UnsupportedOperationException::class)
    fun `ml-kem public keys cannot sign`() {
        KeyAlgorithm.fromPublicKey(publicKey("ML-KEM-768"))
    }
}
