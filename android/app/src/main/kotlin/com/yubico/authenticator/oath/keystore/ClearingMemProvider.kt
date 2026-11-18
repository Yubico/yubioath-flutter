/*
 * Copyright (C) 2022-2025 Yubico.
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

package com.yubico.authenticator.oath.keystore

import android.security.keystore.KeyProperties
import com.yubico.authenticator.CredentialCache
import com.yubico.yubikit.oath.AccessKey
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

class ClearingMemProvider(private val keys: CredentialCache<String, Mac> = CredentialCache()) :
    KeyProvider {
    override fun hasKey(deviceId: String): Boolean = keys.containsKey(deviceId)

    override fun getKey(deviceId: String): AccessKey? = keys[deviceId]?.let { MemStoredSigner(it) }

    override fun putKey(deviceId: String, secret: ByteArray) {
        keys.clear()
        keys[deviceId] =
            Mac.getInstance(KeyProperties.KEY_ALGORITHM_HMAC_SHA1)
                .apply {
                    init(SecretKeySpec(secret, algorithm))
                }
    }

    override fun removeKey(deviceId: String) {
        keys.clear()
    }

    fun clearAll() {
        keys.clear()
    }

    private inner class MemStoredSigner(val mac: Mac) : AccessKey {
        override fun calculateResponse(challenge: ByteArray): ByteArray = mac.doFinal(challenge)
    }
}
