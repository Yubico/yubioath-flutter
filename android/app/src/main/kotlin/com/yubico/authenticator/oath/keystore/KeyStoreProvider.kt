package com.yubico.authenticator.oath.keystore

import android.security.keystore.KeyProperties
import android.security.keystore.KeyProtection
import com.yubico.yubikit.oath.AccessKey
import java.security.KeyStore
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

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
                SecretKeySpec(secret, KeyProperties.KEY_ALGORITHM_HMAC_SHA1)
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
        val mac: Mac = Mac.getInstance(KeyProperties.KEY_ALGORITHM_HMAC_SHA1).apply {
            init(keystore.getKey(getAlias(deviceId), null))
        }

        override fun calculateResponse(challenge: ByteArray): ByteArray = mac.doFinal(challenge)
    }

    // return key alias used in legacy app
    private fun getAlias(deviceId: String) = "$deviceId,0"

}
