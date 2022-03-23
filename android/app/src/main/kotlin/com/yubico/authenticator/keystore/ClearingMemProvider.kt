package com.yubico.authenticator.keystore

import android.security.keystore.KeyProperties
import com.yubico.yubikit.oath.AccessKey
import java.util.*
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import kotlin.concurrent.schedule

class ClearingMemProvider : KeyProvider {
    private val map = mutableMapOf<String, Mac>()
    private var clearAllTask: TimerTask? = null

    override fun hasKey(deviceId: String): Boolean = map.contains(deviceId)

    override fun getKey(deviceId: String): AccessKey? {

        clearAllTask?.cancel()
        clearAllTask = Timer("clear-memory-keys", false)
            .schedule(5 * 60_000) {
                clearAll()
            }

        map[deviceId]?.let {
            return MemStoredSigner(it)
        }

        return null
    }

    override fun addKey(deviceId: String, secret: ByteArray) {
        map[deviceId] =
            Mac.getInstance(KeyProperties.KEY_ALGORITHM_HMAC_SHA1)
                .apply {
                    init(SecretKeySpec(secret, algorithm))
                }
    }

    override fun removeKey(deviceId: String) {
        map.remove(deviceId)
    }

    override fun clearAll() = map.clear()

    private inner class MemStoredSigner(val mac: Mac) : AccessKey {
        override fun calculateResponse(challenge: ByteArray?): ByteArray? = mac.doFinal(challenge)
    }
}