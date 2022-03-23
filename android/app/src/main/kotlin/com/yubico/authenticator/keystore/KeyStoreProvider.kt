package com.yubico.authenticator.keystore

import android.security.keystore.KeyProperties
import android.security.keystore.KeyProtection
import com.yubico.yubikit.oath.AccessKey
import java.security.KeyStore
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

class KeyStoreProvider : KeyProvider {
    private val keystore = KeyStore.getInstance("AndroidKeyStore")
    private val entries = hashMapOf<String, MutableSet<String>>()

    init {
        keystore.load(null)
        keystore.aliases().asSequence().map {
            it.split(',', limit = 2)
        }.forEach {
            entries.getOrPut(it[0]) { mutableSetOf() }.add(it[1])
        }
    }

    override fun hasKeys(deviceId: String): Boolean = entries[deviceId].orEmpty().isNotEmpty()

    override fun getKeys(deviceId: String): Sequence<AccessKey> {
        return entries[deviceId].orEmpty().sorted().asSequence().map {
            KeyStoreStoredSigner(deviceId, it)
        }
    }

    override fun addKey(deviceId: String, secret: ByteArray) {
        val keys = entries.getOrPut(deviceId) { mutableSetOf() }
        val secretId = (0..keys.size).map { "$it" }.find { !keys.contains(it) }
            ?: throw RuntimeException()  // Can't happen
        val alias = "$deviceId,$secretId"
        keystore.setEntry(
            alias,
            KeyStore.SecretKeyEntry(
                SecretKeySpec(secret, KeyProperties.KEY_ALGORITHM_HMAC_SHA1)
            ),
            KeyProtection.Builder(KeyProperties.PURPOSE_SIGN).build()
        )
        keys.add(secretId)
    }


    override fun clearKeys(deviceId: String) {
        entries.remove(deviceId).orEmpty().forEach {
            keystore.deleteEntry("$deviceId,$it")
        }
    }

    override fun clearAll() {
        keystore.aliases().asSequence().forEach { keystore.deleteEntry(it) }
        entries.clear()
    }

    private inner class KeyStoreStoredSigner(val deviceId: String, val secretId: String) :
        AccessKey {
        val mac: Mac = Mac.getInstance(KeyProperties.KEY_ALGORITHM_HMAC_SHA1).apply {
            init(keystore.getKey("$deviceId,$secretId", null))
        }

        override fun calculateResponse(challenge: ByteArray?): ByteArray? = mac.doFinal(challenge)
    }
}