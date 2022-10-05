package com.yubico.authenticator.oath.keystore

import android.os.Build
import android.security.keystore.KeyProperties
import com.yubico.yubikit.oath.AccessKey

interface KeyProvider {
    fun hasKey(deviceId: String): Boolean
    fun getKey(deviceId: String): AccessKey?
    fun putKey(deviceId: String, secret: ByteArray)
    fun removeKey(deviceId: String)
    fun clearAll()
}

fun getAlias(deviceId: String) = "$deviceId,0"

val KEY_ALGORITHM_HMAC_SHA1 = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
    KeyProperties.KEY_ALGORITHM_HMAC_SHA1
} else {
    "HmacSHA1"
}