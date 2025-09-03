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
import org.bouncycastle.asn1.ASN1Primitive
import org.bouncycastle.asn1.pkcs.PrivateKeyInfo
import org.bouncycastle.asn1.sec.ECPrivateKey
import org.bouncycastle.cert.X509CertificateHolder
import org.bouncycastle.jce.ECNamedCurveTable
import org.bouncycastle.jce.spec.ECPrivateKeySpec
import org.bouncycastle.openssl.PEMEncryptedKeyPair
import org.bouncycastle.openssl.PEMKeyPair
import org.bouncycastle.openssl.PEMParser
import org.bouncycastle.openssl.jcajce.JcaPEMKeyConverter
import org.bouncycastle.openssl.jcajce.JcaPEMWriter
import org.bouncycastle.openssl.jcajce.JceOpenSSLPKCS8DecryptorProviderBuilder
import org.bouncycastle.openssl.jcajce.JcePEMDecryptorProviderBuilder
import org.bouncycastle.pkcs.PKCS10CertificationRequest
import org.bouncycastle.pkcs.PKCS8EncryptedPrivateKeyInfo
import java.io.ByteArrayInputStream
import java.io.IOException
import java.io.StringReader
import java.io.StringWriter
import java.security.KeyFactory
import java.security.KeyStore
import java.security.PrivateKey
import java.security.PublicKey
import java.security.UnrecoverableKeyException
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.security.spec.PKCS8EncodedKeySpec
import java.util.Arrays
import javax.crypto.EncryptedPrivateKeyInfo
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec
import javax.security.auth.x500.X500Principal

typealias KeyMaterial = Pair<List<X509Certificate>, PrivateKey?>

class InvalidPasswordException(cause: Throwable) : Exception(cause)

object KeyMaterialParser {

    private class InvalidDerFormat : Exception()

    fun PublicKey.toPem(): String {
        val sw = StringWriter()
        JcaPEMWriter(sw).use { it.writeObject(this) }
        return sw.toString()
    }

    fun PKCS10CertificationRequest.toPem(): String {
        val sw = StringWriter()
        JcaPEMWriter(sw).use { it.writeObject(this) }
        return sw.toString()
    }

    fun X509Certificate.toPem(): String {
        val sw = StringWriter()
        JcaPEMWriter(sw).use { it.writeObject(this) }
        return sw.toString()
    }

    fun getLeafCertificates(certs: List<X509Certificate>): List<X509Certificate> {
        val issuers: Set<X500Principal> = certs.map { it.issuerX500Principal }.toSet()
        return certs.filter { cert -> cert.subjectX500Principal !in issuers }
    }

    fun parse(bytes: ByteArray, password: CharArray? = null): KeyMaterial = try {
        if (isPem(bytes)) {
            parsePem(bytes, password)
        } else {
            parseBinary(bytes, password)
        }
    } finally {
        password?.let { Arrays.fill(it, 0.toChar()) }
    }

    private fun parsePem(bytes: ByteArray, password: CharArray?): KeyMaterial {
        val pem = String(bytes, Charsets.UTF_8)
        val certs = mutableListOf<X509Certificate>()
        val regex = Regex(
            "-----BEGIN CERTIFICATE-----(.*?)-----END CERTIFICATE-----",
            RegexOption.DOT_MATCHES_ALL
        )
        for (match in regex.findAll(pem)) {
            val base64 = match.groupValues[1].replace("\n", "").replace("\r", "")
            val decoded = Base64.decode(base64, Base64.DEFAULT)
            val cert = CertificateFactory.getInstance("X.509")
                .generateCertificate(ByteArrayInputStream(decoded)) as X509Certificate
            certs.add(cert)
        }
        val key = parsePemPrivateKey(pem, password)
        return KeyMaterial(certs, key)
    }

    private fun parsePemPrivateKey(pem: String, password: CharArray?): PrivateKey? {
        try {
            val pemParser = PEMParser(StringReader(pem))
            var info: Any?
            do {
                info = pemParser.readObject()
                val objectInfo = if (info is X509CertificateHolder) {
                    continue // not a key
                } else if (info is PKCS8EncryptedPrivateKeyInfo) {
                    if (password == null) {
                        throw InvalidPasswordException(
                            Exception("Encrypted private key needs a password")
                        )
                    }
                    val decryptor = JceOpenSSLPKCS8DecryptorProviderBuilder().build(password)
                    info.decryptPrivateKeyInfo(decryptor)
                } else if (info is PEMEncryptedKeyPair) {
                    if (password == null) {
                        throw InvalidPasswordException(
                            Exception("Encrypted private key needs a password")
                        )
                    }
                    val decryptor = JcePEMDecryptorProviderBuilder().build(password)
                    info.decryptKeyPair(decryptor).privateKeyInfo
                } else if (info is PEMKeyPair) {
                    info.privateKeyInfo
                } else info as? PrivateKeyInfo ?: continue
                return JcaPEMKeyConverter().getPrivateKey(objectInfo)
            } while (info != null)
        } catch (_: ClassCastException) {
            return null // not a key
        }

        return null
    }

    private fun parseBinary(bytes: ByteArray, password: CharArray?): KeyMaterial {
        try {
            return parseDer(bytes)
        } catch (e: Exception) {
            when (e) {
                !is InvalidDerFormat -> throw e
            }
        }

        try {
            return parsePkcs12(bytes, password)
        } catch (e: Exception) {
            when (e) {
                is UnrecoverableKeyException, is NullPointerException, is IOException
                    -> throw InvalidPasswordException(e)
            }
        }

        return KeyMaterial(emptyList(), null)
    }

    private fun parseDer(der: ByteArray): KeyMaterial {
        val derCert = parseDerCert(der)
        if (derCert == null) {
            val derKey = parsePrivateKey(der)
            if (derKey != null) {
                return KeyMaterial(emptyList(), derKey)
            }
        } else {
            return KeyMaterial(derCert, null)
        }
        throw InvalidDerFormat()
    }

    private fun parseDerCert(der: ByteArray): List<X509Certificate>? =
        try {
            listOf(
                CertificateFactory.getInstance("X.509")
                    .generateCertificate(ByteArrayInputStream(der)) as X509Certificate
            )
        } catch (_: Exception) {
            null // not a cert
        }

    private fun parsePrivateKey(bytes: ByteArray, password: CharArray? = null): PrivateKey? {
        val keySpec = if (password != null) {
            val encryptedPrivateKeyInfo = EncryptedPrivateKeyInfo(bytes)
            val keyFactory = SecretKeyFactory.getInstance(encryptedPrivateKeyInfo.algName)
            val pbeKeySpec = PBEKeySpec(password)
            val secretKey = keyFactory.generateSecret(pbeKeySpec)
            encryptedPrivateKeyInfo.getKeySpec(secretKey)
        } else {
            PKCS8EncodedKeySpec(bytes)
        }

        for (alg in listOf("RSA", "EC", "DSA", "Ed25519", "X25519")) {
            try {
                return KeyFactory.getInstance(alg).generatePrivate(keySpec)
            } catch (_: Exception) {
                // Ignore and try next
            }
        }

        try {
            // try SEC1
            val asn1 = ASN1Primitive.fromByteArray(bytes)

            val ecPrivateKey = ECPrivateKey.getInstance(asn1)
            val d = ecPrivateKey.key

            // TODO P-256
            val ecSpec = ECNamedCurveTable.getParameterSpec("secp384r1")
            val privateKeySpec = ECPrivateKeySpec(d, ecSpec)
            val kf = KeyFactory.getInstance("EC", "BC")
            return kf.generatePrivate(privateKeySpec)

        } catch (_: Exception) {
            // was not SEC1
        }

        return null
    }

    private fun parsePkcs12(
        bytes: ByteArray,
        password: CharArray?
    ): KeyMaterial {
        val keyStore = KeyStore.getInstance("PKCS12")
        keyStore.load(ByteArrayInputStream(bytes), password)
        val certs = mutableListOf<X509Certificate>()
        val aliases = keyStore.aliases()
        while (aliases.hasMoreElements()) {
            val alias = aliases.nextElement()
            val cert = keyStore.getCertificate(alias)
            if (cert is X509Certificate) {
                certs.add(cert)
            }
        }

        val chosenAlias = keyStore.aliases().toList().firstOrNull()
        val key = if (chosenAlias != null) {
            keyStore.getKey(chosenAlias, password) as? PrivateKey
        } else null

        return KeyMaterial(certs, key)
    }

    private fun isPem(bytes: ByteArray): Boolean =
        String(bytes, Charsets.UTF_8).contains("-----BEGIN")
}