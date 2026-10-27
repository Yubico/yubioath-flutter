/*
 * Copyright (C) 2024 Yubico.
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

package com.yubico.authenticator.fido

import com.yubico.authenticator.CredentialCache
import com.yubico.yubikit.core.fido.CtapException

class FidoPinStore(
    onExpired: () -> Unit = {},
    private val cache: CredentialCache<Unit, CharArray> = CredentialCache(
        copy = { it.clone() },
        clearValue = { it.fill(0.toChar()) },
        onExpired = { onExpired() }
    )
) {
    fun hasPin(): Boolean = cache.containsKey(Unit)

    fun getPinOrNull(): CharArray? = cache[Unit]

    fun getPin(): CharArray = getPinOrNull() ?: throw CtapException(CtapException.ERR_PUAT_REQUIRED)

    fun setPin(newPin: CharArray?) {
        if (newPin == null) {
            cache.remove(Unit)
        } else {
            cache[Unit] = newPin
        }
    }
}
