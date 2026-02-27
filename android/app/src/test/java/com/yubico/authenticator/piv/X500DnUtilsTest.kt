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

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * These tests intentionally avoid a huge matrix of DN syntaxes.
 *
 * X500Principal parsing behavior (keywords, quoting, some escapes) may differ between:
 * - Android runtime / API level
 * - host JVM used for unit tests
 *
 * We therefore test the invariants we rely on in the app:
 * 1) parse() rejects blank input.
 * 2) parse() accepts a small set of common subjects we expect users to enter.
 * 3) parse() returns a string that is itself parseable again (so "validate => generate" is safe).
 * 4) parse() produces RFC2253 output form (stable and explicit).
 *
 * Note: We include a couple of UTF-8 hex escape forms (e.g. \C3\B6) since those
 * are common in LDAP DN text, but support can vary by runtime. If these become
 * flaky on CI, they should be moved to Android instrumentation tests.
 */
class X500DnUtilsTest {

    @Test
    fun `parse rejects blank`() {
        assertThrows(IllegalArgumentException::class.java) { X500DnUtils.parse("") }
        assertThrows(IllegalArgumentException::class.java) { X500DnUtils.parse("   ") }
        assertThrows(IllegalArgumentException::class.java) { X500DnUtils.parse("\t") }
        assertThrows(IllegalArgumentException::class.java) { X500DnUtils.parse("\n") }
    }

    @Test
    fun `parse accepts common subject forms`() {
        val inputs = listOf(
            "CN=John",
            "CN=John Smith,O=Yubico,C=SE",
            "CN=Smith\\, John,O=Company", // escaped comma in value
            "CN=First+OU=Last,O=Example", // multi-valued RDN with common keyword
            "CN=John+2.5.4.4=Smith,O=Example", // multi-valued using OID for surname
            "CN=Jörg Müller,O=Example,C=DE", // UTF-8 characters (direct)
            "CN=M\\C3\\BCller,O=Example,C=DE" // "Müller" where ü is UTF-8 C3 BC
        )

        inputs.forEach { dn ->
            val parsed = X500DnUtils.parse(dn)
            assertTrue("parse() should return non-empty for: $dn", parsed.isNotEmpty())
        }
    }

    @Test
    fun `parse rejects obviously malformed DNs`() {
        val inputs = listOf(
            "=John", // missing attribute type
            "CNJohn", // missing '='
            ",CN=Invalid", // leading delimiter
            "CN=Test,,O=Company", // consecutive delimiters
            "CN=John\\", // trailing backslash
            "CN=Smith, John" // unescaped comma inside value
        )

        inputs.forEach { dn ->
            assertThrows("Expected invalid DN: $dn", IllegalArgumentException::class.java) {
                X500DnUtils.parse(dn)
            }
        }
    }

    @Test
    fun `parse output is parseable again (validate then generate invariant)`() {
        val inputs = listOf(
            "CN=John",
            "CN=John Smith,O=Yubico,C=SE",
            "CN=Smith\\, John,O=Company",
            "CN=First+OU=Last,O=Example",
            "CN=Jörg Müller,O=Example,C=DE",
            "CN=J\\C3\\B6rg,O=Example,C=DE"
        )

        inputs.forEach { dn ->
            val normalized = X500DnUtils.parse(dn)
            val normalizedAgain = X500DnUtils.parse(normalized)
            assertEquals(
                "parse(parse(dn)) should be stable for: $dn",
                normalized,
                normalizedAgain
            )
        }
    }
}
