package com.yubico.authenticator.keystore

import android.security.keystore.KeyProperties
import com.yubico.yubikit.oath.AccessKey
import java.util.*
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import kotlin.concurrent.schedule

class ClearingMemProvider : KeyProvider {
    private val map = mutableMapOf<String, MutableSet<Mac>>()
    private var clearAllTask: TimerTask? = null;

    override fun hasKeys(deviceId: String): Boolean = map.contains(deviceId)

    override fun getKeys(deviceId: String): Sequence<AccessKey> {
        clearAllTask?.cancel()
        clearAllTask = Timer("clear-memory-keys", false)
            .schedule(5 * 60_000) {
                clearAll()
            }

        return map[deviceId].orEmpty().asSequence().map { MemStoredSigner(deviceId, it) }
    }

    override fun addKey(deviceId: String, secret: ByteArray) {
        map.getOrPut(deviceId) { mutableSetOf() }.add(
            Mac.getInstance(KeyProperties.KEY_ALGORITHM_HMAC_SHA1)
                .apply {
                    init(SecretKeySpec(secret, algorithm))
                }
        )
    }

    override fun clearKeys(deviceId: String) {
        map[deviceId]?.clear()
    }

    override fun clearAll() = map.clear()

    private inner class MemStoredSigner(val deviceId: String, val mac: Mac) : AccessKey {
        override fun calculateResponse(challenge: ByteArray?): ByteArray? = mac.doFinal(challenge)
    }
}