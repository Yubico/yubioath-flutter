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

import android.os.SystemClock
import java.util.Timer
import java.util.TimerTask

/**
 * Transient credentials with a per-entry, three-minute idle timeout.
 * Only a successful [get] renews an entry; presence checks do not.
 */
class CredentialCache<K, V>(
    private val copy: (V) -> V = { it },
    private val clearValue: (V) -> Unit = {},
    private val onExpired: (K) -> Unit = {},
    private val now: () -> Long = SystemClock::elapsedRealtime,
    private val timer: Timer = expiryTimer
) {
    companion object {
        const val IDLE_TIMEOUT_MS = 3 * 60_000L
        private val expiryTimer = Timer("credential-cache-expiry", true)
    }

    private class Entry<V>(val value: V, var lastAccess: Long)

    private val entries = mutableMapOf<K, Entry<V>>()
    private var expiryTask: TimerTask? = null

    @Synchronized
    operator fun get(key: K): V? {
        val entry = validEntry(key) ?: return null
        entry.lastAccess = now()
        scheduleExpiry()
        return copy(entry.value)
    }

    @Synchronized
    fun containsKey(key: K): Boolean = validEntry(key) != null

    @Synchronized
    operator fun set(key: K, value: V) {
        val stored = copy(value)
        entries.remove(key)?.let { clearValue(it.value) }
        entries[key] = Entry(stored, now())
        scheduleExpiry()
    }

    @Synchronized
    fun remove(key: K) {
        entries.remove(key)?.let { clearValue(it.value) }
        scheduleExpiry()
    }

    @Synchronized
    fun clear() {
        entries.values.forEach { clearValue(it.value) }
        entries.clear()
        scheduleExpiry()
    }

    private fun validEntry(key: K): Entry<V>? {
        val entry = entries[key] ?: return null
        // Check the deadline even if a timer was delayed by device sleep.
        if (now() - entry.lastAccess >= IDLE_TIMEOUT_MS) {
            remove(key)
            onExpired(key)
            return null
        }
        return entry
    }

    @Synchronized
    private fun expire() {
        val time = now()
        val expired = entries.filterValues { time - it.lastAccess >= IDLE_TIMEOUT_MS }.keys
        for (key in expired) {
            entries.remove(key)?.let { clearValue(it.value) }
            onExpired(key)
        }
        scheduleExpiry()
    }

    private fun scheduleExpiry() {
        expiryTask?.cancel()
        expiryTask = null
        timer.purge()
        val deadline = entries.values.minOfOrNull { it.lastAccess + IDLE_TIMEOUT_MS } ?: return
        expiryTask = object : TimerTask() {
            override fun run() = expire()
        }.also {
            timer.schedule(it, (deadline - now()).coerceAtLeast(0))
        }
    }
}
