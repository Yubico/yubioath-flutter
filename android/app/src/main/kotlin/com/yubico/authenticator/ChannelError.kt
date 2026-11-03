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
import java.util.concurrent.CancellationException

/**
 * An error reported to Flutter in the same `{status, message, body}` format the
 * desktop helper uses, so the Dart side decodes every platform the same way.
 *
 * The status names are listed in doc/Error_Contract.adoc. Reuse an existing name
 * when the meaning matches; add a new one to that document before using it.
 */
class ChannelError(
    val status: String,
    override val message: String,
    val body: Map<String, Any?> = emptyMap()
) : Exception(message) {
    companion object {
        const val CANCELLED = "cancelled"
        const val AUTH_REQUIRED = "auth-required"
        const val PASSWORD_REQUIRED = "password-required"
        const val NOT_SUPPORTED = "not-supported"
        const val ALREADY_EXISTS = "already-exists"
        const val CONNECTION_ERROR = "connection-error"
        const val USER_ACTION_TIMEOUT = "user-action-timeout"
        const val NOT_ALLOWED = "not-allowed"
        const val DEVICE_ERROR = "device-error"
        const val EXCEPTION = "exception"
    }
}

/** Turns anything thrown by a channel method into a [ChannelError]. */
fun interface ChannelErrorMapper {
    fun map(error: Throwable): ChannelError
}

/**
 * Mapping shared by every application. App-specific mappers handle their own
 * cases first and fall back to this.
 */
object CommonChannelErrorMapper : ChannelErrorMapper {
    override fun map(error: Throwable): ChannelError = when (error) {
        is ChannelError -> error

        is CancellationException -> ChannelError(
            ChannelError.CANCELLED,
            "Operation cancelled"
        )

        is FunctionalityMissingException -> ChannelError(
            ChannelError.NOT_SUPPORTED,
            "Functionality missing or disabled"
        )

        is TagLostException -> ChannelError(
            ChannelError.CONNECTION_ERROR,
            "NFC communication issue",
            mapOf("connection" to "nfc")
        )

        is CtapException -> mapCtapException(error)

        is ApduException -> ChannelError(
            ChannelError.DEVICE_ERROR,
            "SW: 0x%04x".format(error.sw.toInt() and 0xffff),
            mapOf("sw" to (error.sw.toInt() and 0xffff))
        )

        else -> ChannelError(ChannelError.EXCEPTION, error.toString())
    }
}

private fun mapCtapException(error: CtapException): ChannelError {
    val code = error.ctapError.toInt() and 0xff
    return when (error.ctapError) {
        CtapException.ERR_KEEPALIVE_CANCEL -> ChannelError(
            ChannelError.CANCELLED,
            "Operation cancelled"
        )

        CtapException.ERR_USER_ACTION_TIMEOUT,
        CtapException.ERR_ACTION_TIMEOUT -> ChannelError(
            ChannelError.USER_ACTION_TIMEOUT,
            "Failed action due to user inactivity"
        )

        CtapException.ERR_NOT_ALLOWED -> ChannelError(
            ChannelError.NOT_ALLOWED,
            error.message ?: "Operation not allowed"
        )

        else -> ChannelError(
            ChannelError.DEVICE_ERROR,
            error.message ?: "CTAP error: 0x%02x".format(code),
            mapOf("ctap" to code)
        )
    }
}
