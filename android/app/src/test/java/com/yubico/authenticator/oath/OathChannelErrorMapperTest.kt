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

package com.yubico.authenticator.oath

import com.yubico.yubikit.core.smartcard.ApduException
import com.yubico.yubikit.core.smartcard.SW
import java.util.concurrent.CancellationException
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * Pins the OATH-specific errors the OATH channel sends to Flutter. Everything else falls back to
 * the shared mapping, covered by `CommonChannelErrorMapperTest`.
 */
class OathChannelErrorMapperTest {

    private fun apdu(sw: Short) = ApduException(byteArrayOf(), sw)

    @Test
    fun `security condition not satisfied means auth required`() {
        val error = OathChannelErrorMapper.map(apdu(SW.SECURITY_CONDITION_NOT_SATISFIED))
        assertEquals("auth-required", error.status)
    }

    @Test
    fun `conditions not satisfied means password required`() {
        val error = OathChannelErrorMapper.map(apdu(SW.CONDITIONS_NOT_SATISFIED))
        assertEquals("password-required", error.status)
    }

    @Test
    fun `other apdu errors fall back to device errors`() {
        val error = OathChannelErrorMapper.map(apdu(SW.FILE_NOT_FOUND))
        assertEquals("device-error", error.status)
        assertEquals(mapOf("sw" to 0x6A82), error.body)
    }

    @Test
    fun `other errors fall back to the shared mapping`() {
        assertEquals("cancelled", OathChannelErrorMapper.map(CancellationException()).status)
    }
}
