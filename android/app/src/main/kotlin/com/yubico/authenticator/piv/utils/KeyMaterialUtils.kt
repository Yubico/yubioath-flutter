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

import android.util.Base64
import com.yubico.authenticator.piv.data.hexStringToByteArray
import java.io.ByteArrayInputStream
import java.io.IOException
import java.security.KeyFactory
import java.security.KeyStore
import java.security.PrivateKey
import java.security.PublicKey
import java.security.UnrecoverableKeyException
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate
import java.security.spec.PKCS8EncodedKeySpec
import javax.security.auth.x500.X500Principal

typealias KeyMaterial = Pair<List<X509Certificate>, PrivateKey?>

class InvalidPasswordException(cause: Throwable) : Exception(cause)

object KeyMaterialUtils {

    private class InvalidDerFormat : Exception()

    fun PublicKey.toPem(): String {
        val base64 = Base64.encodeToString(encoded, Base64.NO_WRAP)
        val wrapped = base64.chunked(64).joinToString("\n")
        return "-----BEGIN PUBLIC KEY-----\n$wrapped\n-----END PUBLIC KEY-----\n"
    }

    fun getLeafCertificates(certs: List<X509Certificate>): List<X509Certificate> {
        val issuers: Set<X500Principal> = certs.map { it.issuerX500Principal }.toSet()
        return certs.filter { cert -> cert.subjectX500Principal !in issuers }
    }

    fun parse(bytes: ByteArray, password: String? = null): KeyMaterial {
        return if (isPem(bytes)) {
            parsePem(bytes)
        } else {
            parseBinary(bytes, password)
        }
    }

    private fun parsePem(bytes: ByteArray): KeyMaterial {
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
        val key = parsePemPrivateKey(pem)
        return KeyMaterial(certs, key)
    }

    private fun parsePemPrivateKey(pem: String): PrivateKey? {
        val pkcs8Regex = Regex(
            "-----BEGIN PRIVATE KEY-----(.*?)-----END PRIVATE KEY-----",
            RegexOption.DOT_MATCHES_ALL
        )
        val match = pkcs8Regex.find(pem)
        if (match != null) {
            val base64 = match.groupValues[1].replace("\n", "").replace("\r", "")
            val decoded = Base64.decode(base64, Base64.DEFAULT)
            return generatePkcs8PrivateKey(decoded)
        }

        // TODO EC PRIVATE KEY - SEC1 (RFC 5915)
        // TODO ED25519 PRIVATE KEY
        // TODO ENCRYPTED PRIVATE KEY
        val pkcs1Regex = Regex(
            "-----BEGIN RSA PRIVATE KEY-----(.*?)-----END RSA PRIVATE KEY-----",
            RegexOption.DOT_MATCHES_ALL
        )
        val matchRsa = pkcs1Regex.find(pem)
        if (matchRsa != null) {
            val base64 = matchRsa.groupValues[1]
                .replace("\n", "")
                .replace("\r", "")
            val decoded = Base64.decode(base64, Base64.DEFAULT)
            return pkcs1ToPkcs8(decoded)
        }
        return null
    }

    private fun generatePkcs8PrivateKey(encoded: ByteArray): PrivateKey? {
        try {
            val keySpec = PKCS8EncodedKeySpec(encoded)
            try {
                return KeyFactory.getInstance("RSA").generatePrivate(keySpec)
            } catch (_: Exception) {
            }
            try {
                return KeyFactory.getInstance("EC").generatePrivate(keySpec)
            } catch (_: Exception) {
            }
            try {
                return KeyFactory.getInstance("DSA").generatePrivate(keySpec)
            } catch (_: Exception) {
            }
        } catch (_: Exception) {
        }
        return null
    }

    private fun pkcs1ToPkcs8(pkcs1Bytes: ByteArray): PrivateKey? {
        // TODO
        return null
    }

    private fun parseBinary(bytes: ByteArray, password: String?): KeyMaterial {
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
                is UnrecoverableKeyException, is NullPointerException, is IOException -> throw InvalidPasswordException(
                    e
                )
            }
        }

        return KeyMaterial(emptyList(), null)
    }

    private fun parseDer(der: ByteArray): KeyMaterial {
        val derCert = parseDerCert(der)
        val derKey = parseDerPrivateKey(der)

        if (derCert == null && derKey == null) {
            throw InvalidDerFormat()
        }

        return KeyMaterial(derCert ?: emptyList(), derKey)
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

    private fun parseDerPrivateKey(der: ByteArray): PrivateKey? {
        val keySpec = PKCS8EncodedKeySpec(der)
        try {
            return KeyFactory.getInstance("RSA").generatePrivate(keySpec)
        } catch (_: Exception) {
        }

        try {
            return KeyFactory.getInstance("EC").generatePrivate(keySpec)
        } catch (_: Exception) {
        }

        try {
            return KeyFactory.getInstance("DSA").generatePrivate(keySpec)
        } catch (_: Exception) {
        }
        return null
    }

    private fun parsePkcs12(
        bytes: ByteArray,
        password: String?
    ): KeyMaterial {
        val keyStore = KeyStore.getInstance("PKCS12")
        keyStore.load(ByteArrayInputStream(bytes), password?.toCharArray())
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
            keyStore.getKey(chosenAlias, password?.toCharArray()) as? PrivateKey
        } else null

        return KeyMaterial(certs, key)
    }

    private fun isPem(bytes: ByteArray): Boolean =
        String(bytes.take(10).toByteArray(), Charsets.UTF_8).startsWith("-----BEGIN")
}