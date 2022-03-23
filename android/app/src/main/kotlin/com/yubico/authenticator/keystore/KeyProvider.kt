package com.yubico.authenticator.keystore

import com.yubico.yubikit.oath.AccessKey

interface KeyProvider {
    fun hasKeys(deviceId: String): Boolean
    fun getKeys(deviceId: String): Sequence<AccessKey>
    fun addKey(deviceId: String, secret: ByteArray)
    fun clearKeys(deviceId: String)
    fun clearAll()
}