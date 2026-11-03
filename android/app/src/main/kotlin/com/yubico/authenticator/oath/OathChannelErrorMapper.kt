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

import com.yubico.authenticator.ChannelError
import com.yubico.authenticator.ChannelErrorMapper
import com.yubico.authenticator.CommonChannelErrorMapper
import com.yubico.yubikit.core.smartcard.ApduException
import com.yubico.yubikit.core.smartcard.SW

object OathChannelErrorMapper : ChannelErrorMapper {
    override fun map(error: Throwable): ChannelError = when {
        // The OATH application is locked.
        error is ApduException && error.sw == SW.SECURITY_CONDITION_NOT_SATISFIED ->
            ChannelError(ChannelError.AUTH_REQUIRED, "Authentication is required")

        // The YubiKey refuses to store accounts until a password is set, as
        // FIPS YubiKeys do.
        error is ApduException && error.sw == SW.CONDITIONS_NOT_SATISFIED ->
            ChannelError(ChannelError.PASSWORD_REQUIRED, "Password is required")

        else -> CommonChannelErrorMapper.map(error)
    }
}
