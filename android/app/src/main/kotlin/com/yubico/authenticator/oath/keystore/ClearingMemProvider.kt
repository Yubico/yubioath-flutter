/*
 * Copyright (C) 2022 Yubico.
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
import com.yubico.yubikit.oath.AccessKey
import java.util.*
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import kotlin.concurrent.schedule

class ClearingMemProvider : KeyProvider {
    private var current: Pair<String, Mac>? = null
    private var clearAllTask: TimerTask? = null

    override fun hasKey(deviceId: String): Boolean = current?.first == deviceId

    override fun getKey(deviceId: String): AccessKey? {

        clearAllTask?.cancel()
        clearAllTask = Timer("clear-memory-keys", false)
            .schedule(5 * 60_000) {
                clearAll()
            }

        current?.let {
            if (it.first == deviceId) {
                return MemStoredSigner(it.second)
            }
        }

        return null
    }

    override fun putKey(deviceId: String, secret: ByteArray) {
        current = Pair(deviceId,
            Mac.getInstance(KEY_ALGORITHM_HMAC_SHA1)
                .apply {
                    init(SecretKeySpec(secret, algorithm))
                }
        )
    }

    override fun removeKey(deviceId: String) {
        current = null
    }

    override fun clearAll() {
        current = null
    }

    private inner class MemStoredSigner(val mac: Mac) : AccessKey {
        override fun calculateResponse(challenge: ByteArray): ByteArray = mac.doFinal(challenge)
    }
}
