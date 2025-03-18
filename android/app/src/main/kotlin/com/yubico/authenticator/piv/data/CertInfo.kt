package com.yubico.authenticator.piv.data

import com.yubico.yubikit.piv.KeyType
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.security.cert.X509Certificate

@Serializable
data class CertInfo(
    @SerialName("key_type")
    val keyType: UByte,
    val subject: String,
    val issuer: String,
    val serial: String,
    @SerialName("not_valid_before")
    val notValidBefore: String,
    @SerialName("not_valid_after")
    val notValidAfter: String,
    val fingerprint: String,
) {
    constructor(certificate: X509Certificate) : this(
        KeyType.fromKey(certificate.publicKey).value.toUByte(),
        certificate.subjectDN.toString(),
        certificate.issuerDN.toString(),
        certificate.serialNumber.toByteArray().byteArrayToHexString(),
        certificate.notBefore.isoFormat(),
        certificate.notAfter.isoFormat(),
        certificate.fingerprint()
    )
}
