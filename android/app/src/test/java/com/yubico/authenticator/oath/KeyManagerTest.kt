/*
 * Copyright (C) 2022 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.yubico.authenticator.oath

import com.yubico.authenticator.oath.keystore.KeyProvider
import com.yubico.yubikit.oath.AccessKey
import org.junit.Assert
import org.junit.Before
import org.junit.Test

/**
 *  Implementation of [AccessKey] which returns [secret] for any challenge.
 */
class MockStoredSigner(private val secret: ByteArray) : AccessKey {
    override fun calculateResponse(challenge: ByteArray): ByteArray = secret
}

/**
 * Implementation of [KeyProvider] backed by a [Map]
 */
class MockKeyProvider : KeyProvider {
    private val map: MutableMap<String, AccessKey> = mutableMapOf()

    override fun hasKey(deviceId: String): Boolean = map[deviceId] != null

    override fun getKey(deviceId: String): AccessKey? = map[deviceId]

    override fun putKey(deviceId: String, secret: ByteArray) {
        map[deviceId] = MockStoredSigner(secret)
    }

    override fun removeKey(deviceId: String) {
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
        val key1 = keyManager.getKey(device1Id)
        Assert.assertNotNull(key1)
        Assert.assertEquals(secret1, key1!!.calculateResponse(byteArrayOf()))

        keyManager.addKey(device2Id, secret2, false)
        val key2 = keyManager.getKey(device2Id)
        Assert.assertNotNull(key2)
        Assert.assertEquals(secret2, key2!!.calculateResponse(byteArrayOf()))
    }

    @Test
    fun `associates keys with correct devices`() {
        keyManager.addKey(device1Id, secret1, true)

        Assert.assertNotNull(keyManager.getKey(device1Id))
        Assert.assertNull(keyManager.getKey(device2Id))

        keyManager.addKey(device2Id, secret2, false)
        Assert.assertNotNull(keyManager.getKey(device2Id))
        Assert.assertNotNull(keyManager.getKey(device1Id))
    }

    @Test
    fun `clears keys for device`() {
        keyManager.addKey(device1Id, secret1, true)
        keyManager.addKey(device2Id, secret2, true)

        keyManager.removeKey(device1Id)

        Assert.assertNotNull(keyManager.getKey(device2Id))
        Assert.assertNull(keyManager.getKey(device1Id))
    }

    @Test
    fun `clears all keys`() {
        keyManager.addKey(device1Id, secret1, true)
        keyManager.addKey(device2Id, secret2, false)

        keyManager.clearAll()

        Assert.assertNull(keyManager.getKey(device1Id))
        Assert.assertNull(keyManager.getKey(device2Id))
    }

    @Test
    fun `can overwrite stored key`() {
        keyManager.addKey(device1Id, secret1, true)
        keyManager.addKey(device1Id, secret2, true)

        val key1 = keyManager.getKey(device1Id)
        Assert.assertEquals(secret2, key1!!.calculateResponse(byteArrayOf()))

        keyManager.addKey(device1Id, secret1, true)
        val key2 = keyManager.getKey(device1Id)
        Assert.assertEquals(secret1, key2!!.calculateResponse(byteArrayOf()))
    }
}