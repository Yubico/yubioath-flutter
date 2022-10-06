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

import android.content.Context
import android.util.Base64
import com.yubico.yubikit.oath.AccessKey
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

class SharedPrefProvider(context: Context) : KeyProvider {

    private val prefs = context.getSharedPreferences(SP_STORED_AUTH_KEYS, Context.MODE_PRIVATE)

    override fun hasKey(deviceId: String) = prefs.contains(getAlias(deviceId))

    override fun getKey(deviceId: String): AccessKey? =
        prefs.getStringSet(getAlias(deviceId), null)?.firstOrNull()?.let {
            StringSigner(it)
        }

    override fun putKey(deviceId: String, secret: ByteArray) {
        prefs.edit().putStringSet(getAlias(deviceId), setOf(encode(secret))).apply()
    }

    override fun removeKey(deviceId: String) {
        prefs.edit().remove(getAlias(deviceId)).apply()
    }

    override fun clearAll() {
        prefs.edit().clear().apply()
    }

    private inner class StringSigner(val secret: String) : AccessKey {
        val mac: Mac = Mac.getInstance(KEY_ALGORITHM_HMAC_SHA1).apply {
            init(SecretKeySpec(decode(secret), algorithm))
        }

        override fun calculateResponse(challenge: ByteArray): ByteArray = mac.doFinal(challenge)
    }

    companion object {
        private fun encode(input: ByteArray) =
            Base64.encodeToString(input, Base64.NO_WRAP or Base64.NO_PADDING)

        private fun decode(input: String) = Base64.decode(input, Base64.DEFAULT)

        private const val SP_STORED_AUTH_KEYS = "com.yubico.yubioath.SP_STORED_AUTH_KEYS"
    }
}