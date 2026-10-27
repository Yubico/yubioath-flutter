/*
 * Copyright (C) 2026 Yubico.
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

package com.yubico.authenticator

import androidx.arch.core.executor.testing.InstantTaskExecutorRule
import androidx.lifecycle.Observer
import com.yubico.authenticator.device.Version
import com.yubico.authenticator.fido.FidoPinStore
import com.yubico.authenticator.oath.keystore.ClearingMemProvider
import com.yubico.authenticator.piv.PivViewModel
import com.yubico.authenticator.piv.data.PivState
import com.yubico.yubikit.core.fido.CtapException
import java.util.Timer
import java.util.TimerTask
import javax.crypto.Mac
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

class CredentialCacheTest {
    @get:Rule
    val executorRule = InstantTaskExecutorRule()

    private class ManualTimer : Timer(true) {
        val tasks = mutableListOf<TimerTask>()
        var delay = 0L

        override fun schedule(task: TimerTask, delay: Long) {
            tasks.add(task)
            this.delay = delay
        }
    }

    private val timer = ManualTimer()
    private var now = 0L
    private val expired = mutableListOf<String>()
    private val cache = CredentialCache<String, ByteArray>(
        copy = { it.clone() },
        clearValue = { it.fill(0) },
        onExpired = { expired.add(it) },
        now = { now },
        timer = timer
    )

    @After
    fun tearDown() {
        cache.clear()
        timer.cancel()
    }

    @Test
    fun `expires at exactly three minutes even if the timer is delayed`() {
        for (elapsed in listOf(180_000L, 180_001L, 3_600_000L)) {
            now = 0
            cache["key"] = byteArrayOf(1)
            now = 179_999
            assertTrue(cache.containsKey("key"))
            now = elapsed
            assertNull(cache["key"])
            assertNull(cache["key"])
        }
        assertEquals(listOf("key", "key", "key"), expired)
    }

    @Test
    fun `only retrieving the matching entry refreshes its timeout`() {
        cache["first"] = byteArrayOf(1)
        cache["second"] = byteArrayOf(2)
        now = 120_000
        assertArrayEquals(byteArrayOf(1), cache["first"])
        now = 179_999
        assertTrue(cache.containsKey("second"))
        assertNull(cache["missing"])
        now = 180_000
        assertNull(cache["second"])
        assertTrue(cache.containsKey("first"))
        now = 300_000
        assertNull(cache["first"])
    }

    @Test
    fun `timer clears idle credentials without another access`() {
        var stored: ByteArray? = null
        val cache = CredentialCache<String, ByteArray>(
            copy = { it.clone().also { copy -> stored = copy } },
            clearValue = { it.fill(0) },
            now = { now },
            timer = timer
        )
        cache["key"] = byteArrayOf(1, 2)
        assertEquals(180_000L, timer.delay)
        now = 180_000
        timer.tasks.last().run()
        assertArrayEquals(byteArrayOf(0, 0), stored)
        assertFalse(cache.containsKey("key"))
    }

    @Test
    fun `replacement and explicit removal clear old secrets`() {
        val cleared = mutableListOf<ByteArray>()
        val cache = CredentialCache<String, ByteArray>(
            clearValue = {
                it.fill(0)
                cleared.add(it)
            },
            now = { now },
            timer = timer
        )
        val original = byteArrayOf(1)
        cache["key"] = original
        now = 120_000
        cache["key"] = byteArrayOf(2)
        assertArrayEquals(byteArrayOf(0), original)
        now = 180_000
        timer.tasks.first().run()
        assertTrue(cache.containsKey("key"))
        cache.remove("key")
        assertFalse(cache.containsKey("key"))
        assertEquals(2, cleared.size)
        cache["key"] = byteArrayOf(3)
        cache.clear()
        assertFalse(cache.containsKey("key"))
        assertEquals(3, cleared.size)
    }

    @Test
    fun `reads and writes copy mutable credentials`() {
        val pin = byteArrayOf(1, 2)
        cache["key"] = pin
        pin.fill(0)
        val retrieved = cache["key"]!!
        retrieved.fill(0)
        assertArrayEquals(byteArrayOf(1, 2), cache["key"])
    }

    @Test
    fun `FIDO pin store expires without presence checks extending its lifetime`() {
        val store = FidoPinStore(
            cache = CredentialCache(
                copy = { it.clone() },
                clearValue = { it.fill(0.toChar()) },
                now = { now },
                timer = timer
            )
        )
        store.setPin("123456".toCharArray())
        now = 179_999
        assertTrue(store.hasPin())
        now = 180_000
        assertNull(store.getPinOrNull())
        assertFalse(store.hasPin())
        val error = assertThrows(CtapException::class.java) { store.getPin() }
        assertEquals(CtapException.ERR_PUAT_REQUIRED, error.ctapError)
    }

    @Test
    fun `OATH memory keys expire from insertion and refresh on retrieval only`() {
        val keys = CredentialCache<String, Mac>(now = { now }, timer = timer)
        val provider = ClearingMemProvider(keys)
        provider.putKey("first", byteArrayOf(1))
        now = 120_000
        assertNotNull(provider.getKey("first"))
        now = 180_000
        assertTrue(provider.hasKey("first"))
        assertNull(provider.getKey("missing"))
        now = 300_000
        assertNull(provider.getKey("first"))
        provider.putKey("second", byteArrayOf(2))
        now += 180_000
        assertFalse(provider.hasKey("second"))
    }

    @Test
    fun `PIV expiry invalidates only the matching device authentication`() {
        val viewModel = PivViewModel()
        val state = PivState(
            Version(5, 7, 1),
            authenticated = true,
            derivedKey = false,
            storedKey = true,
            pinAttempts = 3,
            supportsBio = false,
            chuid = null,
            ccc = null,
            metadata = null
        )
        val updates = mutableListOf<PivState>()
        val observer = Observer<ViewModelData> {
            ((it as? ViewModelData.Value<*>)?.data as? PivState)?.let(updates::add)
        }
        viewModel.state.observeForever(observer)
        try {
            viewModel.setSerial(1234)
            viewModel.setState(state)
            viewModel.expireAuthentication("other")
            assertTrue(updates.last().authenticated)
            assertEquals(1, updates.size)
            viewModel.expireAuthentication("1234")
            assertFalse(updates.last().authenticated)
            assertEquals(2, updates.size)
            viewModel.expireAuthentication("1234")
            assertEquals(3, updates.size)
        } finally {
            viewModel.state.removeObserver(observer)
        }
    }
}
