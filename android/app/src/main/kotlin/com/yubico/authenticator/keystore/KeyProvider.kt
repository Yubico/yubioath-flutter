package com.yubico.authenticator.keystore

import com.yubico.yubikit.oath.AccessKey

interface KeyProvider {
    fun hasKey(deviceId: String): Boolean
    fun getKey(deviceId: String): AccessKey?
    fun putKey(deviceId: String, secret: ByteArray)
    fun removeKey(deviceId: String)
    fun clearAll()
}