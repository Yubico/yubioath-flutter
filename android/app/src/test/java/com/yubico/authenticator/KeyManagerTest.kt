package com.yubico.authenticator

import com.yubico.authenticator.keystore.KeyProvider
import com.yubico.yubikit.oath.AccessKey
import org.junit.Assert
import org.junit.Before
import org.junit.Test

/**
 *  Implementation of [StoredSigner] which returns [secret] for any challenge.
 */
class MockStoredSigner(private val secret: ByteArray) : AccessKey {
    override fun calculateResponse(challenge: ByteArray): ByteArray = secret
}

/**
 * Implementation of [KeyProvider] backed by a [Map]
 */
class MockKeyProvider : KeyProvider {
    private val map: MutableMap<String, AccessKey> = mutableMapOf()

    override fun hasKeys(deviceId: String): Boolean = map[deviceId] != null

    override fun getKeys(deviceId: String): Sequence<AccessKey> = sequence {
        map.values.forEach { yield(it) }
    }

    override fun addKey(deviceId: String, secret: ByteArray) {
        map[deviceId] = MockStoredSigner(secret)
    }

    override fun clearKeys(deviceId: String) {
        map.remove(deviceId)
    }

    override fun clearAll() {
        map.clear()
    }
}

class KeyManagerTest {

    private val device1Id = "d1"
    private val device2Id = "d2"
    private val secret1 = "secret".toByteArray()
    private val secret2 = "secret2".toByteArray()

    private lateinit var permKeyProvider: KeyProvider
    private lateinit var memKeyProvider: KeyProvider
    private lateinit var keyManager: KeyManager

    @Before
    fun setUp() {
        permKeyProvider = MockKeyProvider()
        memKeyProvider = MockKeyProvider()

        keyManager = KeyManager(permKeyProvider, memKeyProvider)
    }

    @Test
    fun `adds secret to memory key provider`() {
        keyManager.addKey(device1Id, secret1, false)
        Assert.assertFalse(keyManager.isRemembered(device1Id))
    }

    @Test
    fun `adds secret to permanent key provider`() {
        keyManager.addKey(device1Id, secret1, true)
        Assert.assertTrue(keyManager.isRemembered(device1Id))
    }

    @Test
    fun `returns added key`() {
        keyManager.addKey(device1Id, secret1, true)
        val keys1 = keyManager.getKeys(device1Id).toList()
        Assert.assertEquals(secret1, keys1[0].calculateResponse(byteArrayOf()))

        keyManager.addKey(device2Id, secret2, false)
        val keys2 = keyManager.getKeys(device2Id).toList()
        Assert.assertEquals(secret2, keys2[0].calculateResponse(byteArrayOf()))

    }

    @Test
    fun `associates keys with correct devices`() {
        keyManager.addKey(device1Id, secret1, true)

        Assert.assertEquals(0, keyManager.getKeys(device2Id).toList().size)
        Assert.assertEquals(1, keyManager.getKeys(device1Id).toList().size)

        keyManager.addKey(device2Id, secret2, false)
        Assert.assertEquals(1, keyManager.getKeys(device2Id).toList().size)
        Assert.assertEquals(1, keyManager.getKeys(device1Id).toList().size)
    }

    @Test
    fun `clears keys for device`() {
        keyManager.addKey(device2Id, secret2, true)
        keyManager.addKey(device1Id, secret1, true)

        keyManager.clearKeys(device1Id)

        Assert.assertTrue(keyManager.getKeys(device2Id).toList().size == 1)
        Assert.assertTrue(keyManager.getKeys(device1Id).toList().isEmpty())
    }

    @Test
    fun `clears all keys`() {
        keyManager.addKey(device2Id, secret2, true)
        keyManager.addKey(device1Id, secret1, true)

        keyManager.clearAll()

        Assert.assertTrue(keyManager.getKeys(device2Id).toList().isEmpty())
        Assert.assertTrue(keyManager.getKeys(device1Id).toList().isEmpty())
    }
}