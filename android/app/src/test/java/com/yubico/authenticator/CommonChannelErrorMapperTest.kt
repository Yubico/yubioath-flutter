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

package com.yubico.authenticator

import android.nfc.TagLostException
import com.yubico.yubikit.core.fido.CtapException
import com.yubico.yubikit.core.smartcard.ApduException
import com.yubico.yubikit.core.smartcard.SW
import java.util.concurrent.CancellationException
import org.junit.Assert.assertEquals
import org.junit.Test
import org.mockito.Mockito.mock

/**
 * Pins the errors every channel using [CommonChannelErrorMapper] sends to Flutter. The statuses
 * are decoded by `AppException.fromWire` in `lib/exception/app_exception.dart` and listed in
 * doc/Error_Contract.adoc; `test/exception/app_exception_test.dart` covers the Dart half.
 */
class CommonChannelErrorMapperTest {

    @Test
    fun `cancellation means cancelled`() {
        assertEquals("cancelled", CommonChannelErrorMapper.map(CancellationException()).status)
    }

    @Test
    fun `missing functionality means not supported`() {
        assertEquals(
            "not-supported",
            CommonChannelErrorMapper.map(FunctionalityMissingException()).status
        )
    }

    @Test
    fun `lost nfc tag is a connection error on nfc`() {
        val error = CommonChannelErrorMapper.map(mock(TagLostException::class.java))
        assertEquals("connection-error", error.status)
        assertEquals(mapOf("connection" to "nfc"), error.body)
    }

    @Test
    fun `apdu errors are device errors carrying the status word`() {
        val error = CommonChannelErrorMapper.map(ApduException(byteArrayOf(), SW.FILE_NOT_FOUND))
        assertEquals("device-error", error.status)
        assertEquals(mapOf("sw" to 0x6A82), error.body)
    }

    @Test
    fun `ctap not allowed means not allowed`() {
        val error = CommonChannelErrorMapper.map(CtapException(CtapException.ERR_NOT_ALLOWED))
        assertEquals("not-allowed", error.status)
    }

    @Test
    fun `ctap keepalive cancel means cancelled`() {
        val error = CommonChannelErrorMapper.map(CtapException(CtapException.ERR_KEEPALIVE_CANCEL))
        assertEquals("cancelled", error.status)
    }

    @Test
    fun `ctap timeouts mean user action timeout`() {
        for (code in listOf(
            CtapException.ERR_USER_ACTION_TIMEOUT,
            CtapException.ERR_ACTION_TIMEOUT
        )) {
            assertEquals(
                "user-action-timeout",
                CommonChannelErrorMapper.map(CtapException(code)).status
            )
        }
    }

    @Test
    fun `other ctap errors are device errors carrying the ctap code`() {
        val error = CommonChannelErrorMapper.map(CtapException(CtapException.ERR_PIN_INVALID))
        assertEquals("device-error", error.status)
        assertEquals(mapOf("ctap" to 0x31), error.body)
    }

    @Test
    fun `channel errors pass through unchanged`() {
        val original = ChannelError(ChannelError.ALREADY_EXISTS, "Credential already exists")
        assertEquals(original, CommonChannelErrorMapper.map(original))
    }

    @Test
    fun `anything else is a generic exception`() {
        val error = CommonChannelErrorMapper.map(IllegalStateException("boom"))
        assertEquals("exception", error.status)
        assertEquals("java.lang.IllegalStateException: boom", error.message)
    }
}
