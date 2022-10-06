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

import android.os.Build
import android.security.keystore.KeyProperties
import android.security.keystore.KeyProtection
import androidx.annotation.RequiresApi
import com.yubico.yubikit.oath.AccessKey
import java.security.KeyStore
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

@RequiresApi(Build.VERSION_CODES.M)
class KeyStoreProvider : KeyProvider {
    private val keystore = KeyStore.getInstance("AndroidKeyStore")

    init {
        keystore.load(null)
    }

    override fun hasKey(deviceId: String): Boolean = keystore.containsAlias(getAlias(deviceId))

    override fun getKey(deviceId: String): AccessKey? =
        if (hasKey(deviceId)) {
            KeyStoreStoredSigner(deviceId)
        } else {
            null
        }

    override fun putKey(deviceId: String, secret: ByteArray) {
        keystore.setEntry(
            getAlias(deviceId),
            KeyStore.SecretKeyEntry(
                SecretKeySpec(secret, KEY_ALGORITHM_HMAC_SHA1)
            ),
            KeyProtection.Builder(KeyProperties.PURPOSE_SIGN).build()
        )
    }


    override fun removeKey(deviceId: String) {
        keystore.deleteEntry(getAlias(deviceId))
    }

    override fun clearAll() {
        keystore.aliases().asSequence().forEach { keystore.deleteEntry(it) }
    }

    private inner class KeyStoreStoredSigner(val deviceId: String) :
        AccessKey {
        val mac: Mac = Mac.getInstance(KEY_ALGORITHM_HMAC_SHA1).apply {
            init(keystore.getKey(getAlias(deviceId), null))
        }

        override fun calculateResponse(challenge: ByteArray): ByteArray = mac.doFinal(challenge)
    }
}
