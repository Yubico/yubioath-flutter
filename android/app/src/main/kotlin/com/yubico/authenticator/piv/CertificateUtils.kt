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

import com.yubico.yubikit.piv.KeyType
import com.yubico.yubikit.piv.PivSession
import com.yubico.yubikit.piv.Slot
import org.bouncycastle.asn1.ASN1ObjectIdentifier
import org.bouncycastle.asn1.edec.EdECObjectIdentifiers
import org.bouncycastle.cert.X509CertificateHolder
import org.bouncycastle.cert.jcajce.JcaX509CertificateConverter
import org.bouncycastle.cert.jcajce.JcaX509v3CertificateBuilder
import org.bouncycastle.operator.ContentSigner
import org.bouncycastle.operator.DefaultSignatureAlgorithmIdentifierFinder
import org.bouncycastle.operator.OperatorCreationException
import org.bouncycastle.pkcs.PKCS10CertificationRequest
import org.bouncycastle.pkcs.jcajce.JcaPKCS10CertificationRequestBuilder
import java.io.ByteArrayOutputStream
import java.math.BigInteger
import java.security.GeneralSecurityException
import java.security.KeyFactory
import java.security.PublicKey
import java.security.interfaces.ECPublicKey
import java.security.interfaces.RSAPublicKey
import java.security.spec.X509EncodedKeySpec
import java.util.Date
import javax.security.auth.x500.X500Principal
import java.security.cert.X509Certificate
import org.bouncycastle.asn1.x509.AlgorithmIdentifier
import java.security.SecureRandom
import java.security.Signature

/**
 * Hash algorithms supported for RSA/ECDSA. Ignored for Ed25519.
 */
enum class HashAlgorithm {
    SHA256, SHA384, SHA512
}

/**
 * Abstracts the key algorithm class (RSA, EC, Ed25519).
 */
enum class KeyAlgorithm {
    RSA, EC, ED25519;

    companion object {
        fun fromPublicKey(publicKey: PublicKey): KeyAlgorithm = when (publicKey.algorithm.uppercase()) {
            "RSA" -> RSA
            "EC" -> EC
            // Android/JCA may report Ed25519 as "Ed25519" or "EdDSA"
            "ED25519", "EDDSA" -> ED25519
            // X25519 ("XDH", "X25519") is key agreement only and cannot sign
            "X25519", "XDH" -> throw UnsupportedOperationException("X25519/XDH cannot be used for signing (CSR/cert).")
            else -> {
                // Try to detect by encoded OID if the algorithm string is unexpected.
                val alg = tryDetectFromEncoded(publicKey)
                alg ?: throw UnsupportedOperationException("Unsupported public key algorithm: ${publicKey.algorithm}")
            }
        }

        private fun tryDetectFromEncoded(publicKey: PublicKey): KeyAlgorithm? = try {
            val spec = X509EncodedKeySpec(publicKey.encoded)
            val kfRSA = try { KeyFactory.getInstance("RSA") } catch (_: Exception) { null }
            val kfEC = try { KeyFactory.getInstance("EC") } catch (_: Exception) { null }
            when {
                kfRSA != null && runCatching { kfRSA.generatePublic(spec) as RSAPublicKey }.isSuccess -> RSA
                kfEC != null && runCatching { kfEC.generatePublic(spec) as ECPublicKey }.isSuccess -> EC
                else -> null
            }
        } catch (_: Exception) { null }
    }
}

/**
 * Signature algorithm abstraction; holds the JCA name and (optionally) a fixed AlgorithmIdentifier OID.
 */
sealed class SignatureAlgorithm(val jcaName: String, val fixedAlgId: ASN1ObjectIdentifier? = null) {
    class Rsa(val hash: HashAlgorithm) : SignatureAlgorithm(
        when (hash) {
            HashAlgorithm.SHA256 -> "SHA256withRSA"
            HashAlgorithm.SHA384 -> "SHA384withRSA"
            HashAlgorithm.SHA512 -> "SHA512withRSA"
        }
    )

    class EcDsa(val hash: HashAlgorithm) : SignatureAlgorithm(
        when (hash) {
            HashAlgorithm.SHA256 -> "SHA256withECDSA"
            HashAlgorithm.SHA384 -> "SHA384withECDSA"
            HashAlgorithm.SHA512 -> "SHA512withECDSA"
        }
    )

    object Ed25519 : SignatureAlgorithm("Ed25519", EdECObjectIdentifiers.id_Ed25519)
}

/**
 * Maps a public key + requested hash into a SignatureAlgorithm.
 * - RSA -> SHAxxxwithRSA (PKCS#1 v1.5)
 * - EC  -> SHAxxxwithECDSA
 * - Ed25519 -> Ed25519 (hash ignored)
 */
fun resolveSignatureAlgorithm(publicKey: PublicKey, hash: HashAlgorithm): SignatureAlgorithm {
    return when (KeyAlgorithm.fromPublicKey(publicKey)) {
        KeyAlgorithm.RSA -> SignatureAlgorithm.Rsa(hash)
        KeyAlgorithm.EC -> SignatureAlgorithm.EcDsa(hash)
        KeyAlgorithm.ED25519 -> SignatureAlgorithm.Ed25519
    }
}

class PivContentSigner(
    private val session: PivSession,
    private val slot: Slot,
    private val publicKey: PublicKey,
    private val signatureAlgorithm: SignatureAlgorithm
) : ContentSigner {

    private val buffer = ByteArrayOutputStream()
    private val keyAlg = KeyType.fromKey(publicKey)
    private val algId: AlgorithmIdentifier = run {
        // For Ed25519 we must emit the Ed25519 OID; for others, use the default finder.
        val maybeOid = signatureAlgorithm.fixedAlgId
        if (maybeOid != null) {
            AlgorithmIdentifier(maybeOid)
        } else {
            DefaultSignatureAlgorithmIdentifierFinder().find(signatureAlgorithm.jcaName)
        }
    }

    override fun getAlgorithmIdentifier(): AlgorithmIdentifier = algId

    override fun getOutputStream() = buffer

    @Throws(OperatorCreationException::class)
    override fun getSignature(): ByteArray {
        try {
            val toBeSigned = buffer.toByteArray()
            val signature = Signature.getInstance(signatureAlgorithm.jcaName)
            // TODO use JCA
            return session.sign(slot, keyAlg, toBeSigned, signature)
        } catch (e: GeneralSecurityException) {
            throw OperatorCreationException("PIV signing failed", e)
        }
    }
}

@Throws(GeneralSecurityException::class)
fun signCsrBuilder(
    session: PivSession,
    slot: Slot,
    publicKey: PublicKey,
    builder: JcaPKCS10CertificationRequestBuilder,
    hashAlgorithm: HashAlgorithm = HashAlgorithm.SHA256
): PKCS10CertificationRequest {
    val sigAlg = resolveSignatureAlgorithm(publicKey, hashAlgorithm)
    val signer = PivContentSigner(session, slot, publicKey, sigAlg)
    return builder.build(signer)
}

@Throws(GeneralSecurityException::class)
fun generateCsr(
    session: PivSession,
    slot: Slot,
    publicKey: PublicKey,
    subjectRfc4514: String,
    hashAlgorithm: HashAlgorithm = HashAlgorithm.SHA256
): PKCS10CertificationRequest {
    val subject = X500Principal(subjectRfc4514)
    val builder = JcaPKCS10CertificationRequestBuilder(subject, publicKey)
    return signCsrBuilder(session, slot, publicKey, builder, hashAlgorithm)
}


@Throws(GeneralSecurityException::class)
fun generateSelfSignedCertificate(
    session: PivSession,
    slot: Slot,
    publicKey: PublicKey,
    subjectRfc4514: String,
    notBefore: Date,
    notAfter: Date,
    hashAlgorithm: HashAlgorithm = HashAlgorithm.SHA256
): X509Certificate {
    val subject = X500Principal(subjectRfc4514)
    val serial = randomSerialNumber()

    val certBuilder = JcaX509v3CertificateBuilder(
        subject,
        serial,
        notBefore,
        notAfter,
        subject,
        publicKey
    )

    val sigAlg = resolveSignatureAlgorithm(publicKey, hashAlgorithm)
    val signer = PivContentSigner(session, slot, publicKey, sigAlg)
    val holder: X509CertificateHolder = certBuilder.build(signer)

    return JcaX509CertificateConverter()
        .setProvider("BC")
        .getCertificate(holder)
}

/**
 * Utility to generate a positive random 128-bit serial number.
 * Mirrors the intent of cryptography.x509.random_serial_number().
 */
fun randomSerialNumber(): BigInteger {
    val bits = 128
    val rnd = SecureRandom()
    var serial = BigInteger(bits, rnd)
    if (serial.signum() <= 0) serial = serial.negate()
    return serial
}
