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
