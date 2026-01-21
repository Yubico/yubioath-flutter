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

package com.yubico.authenticator.piv.data

import com.yubico.yubikit.piv.KeyType
import java.security.cert.X509Certificate
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

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
    val fingerprint: String
) {
    constructor(certificate: X509Certificate) : this(
        KeyType.fromKey(certificate.publicKey).value.toUByte(),
        certificate.subjectDN.toString(),
        certificate.issuerDN.toString(),
        certificate.serialNumber.toByteArray().toHexString(),
        certificate.notBefore.isoFormat(),
        certificate.notAfter.isoFormat(),
        certificate.fingerprint()
    )
}
