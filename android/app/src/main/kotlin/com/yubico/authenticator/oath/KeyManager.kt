/*
 * Copyright (c) 2022, Yubico AB.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 *
 *  Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following
 *   disclaimer in the documentation and/or other materials provided
 *   with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
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