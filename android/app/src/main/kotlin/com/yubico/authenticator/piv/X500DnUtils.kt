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

import javax.security.auth.x500.X500Principal

/**
 * Utility for parsing and normalizing X.509 subject/issuer Distinguished Names (DNs).
 *
 * This is used to validate user-provided subject strings and convert them to a canonical
 * string form before they are used for CSR or certificate generation.
 *
 * Supported input features depend on the platform DN parser, but commonly include:
 *
 * - **Special character escaping**: DN delimiter characters may be escaped to be treated as
 *   literal data (e.g., `\,` for a comma in a value).
 * - **Hex escapes**: Byte escapes like `\C3\B6` may be used to represent UTF-8 characters.
 * - **Multi-valued RDNs**: `+` may be used to combine multiple attributes within a single RDN.
 *
 * ## Implementation notes
 *
 * Parsing and normalization are performed using the platform [X500Principal] implementation.
 * If parsing succeeds, the DN is returned in a canonical string form. If parsing fails,
 * an [IllegalArgumentException] is thrown.
 *
 * ## Security considerations
 *
 * Validating and normalizing DNs helps avoid ambiguous interpretations of the same input and
 * prevents delimiter characters from being treated as DN structure when the intent was to
 * include them as literal data.
 */
internal object X500DnUtils {

    /**
     * Parses and normalizes a Distinguished Name (DN) string for use as an X.509 subject/issuer.
     *
     * The input must be accepted by the platform [X500Principal] DN parser. If parsing succeeds,
     * the DN is returned in a canonical string form ([X500Principal.RFC2253]). If parsing fails,
     * an [IllegalArgumentException] is thrown.
     *
     * @param dn The DN string to parse (e.g., "CN=John Smith,O=Yubico,C=SE").
     * @return The normalized DN string in canonical RFC2253 form.
     * @throws IllegalArgumentException if [dn] is blank or invalid.
     */
    fun parse(dn: String): String {
        require(!dn.isBlank()) { "DN cannot be blank" }
        return try {
            X500Principal(dn).getName(X500Principal.RFC2253)
        } catch (e: IllegalArgumentException) {
            throw IllegalArgumentException("Invalid DN: ${e.message}", e)
        }
    }
}
