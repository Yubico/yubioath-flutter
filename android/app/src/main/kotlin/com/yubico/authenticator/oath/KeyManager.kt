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

package com.yubico.authenticator.oath

import com.yubico.authenticator.oath.keystore.KeyProvider
import com.yubico.yubikit.oath.AccessKey

class KeyManager(private val permStore: KeyProvider, private val memStore: KeyProvider) {

    /**
     * @return true if this deviceId is stored in permanent KeyStore
     */
    fun isRemembered(deviceId: String) = permStore.hasKey(deviceId)

    fun getKey(deviceId: String): AccessKey? {
        return if (permStore.hasKey(deviceId)) {
            permStore.getKey(deviceId)
        } else {
            memStore.getKey(deviceId)
        }
    }

    fun addKey(deviceId: String, secret: ByteArray, remember: Boolean) {
        if (remember) {
            memStore.removeKey(deviceId)
            permStore.putKey(deviceId, secret)
        } else {
            permStore.removeKey(deviceId)
            memStore.putKey(deviceId, secret)
        }
    }

    fun removeKey(deviceId: String) {
        memStore.removeKey(deviceId)
        permStore.removeKey(deviceId)
    }

    fun clearAll() {
        memStore.clearAll()
        permStore.clearAll()
    }
}