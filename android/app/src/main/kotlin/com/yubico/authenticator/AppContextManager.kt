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

package com.yubico.authenticator

import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import com.yubico.yubikit.core.YubiKeyDevice

/**
 * Provides behavior to run when a YubiKey is inserted/tapped for a specific view of the app.
 */
abstract class AppContextManager(
    private val lifecycleOwner: LifecycleOwner
) {
    abstract suspend fun processYubiKey(device: YubiKeyDevice)

    private val lifecycleObserver = object : DefaultLifecycleObserver {
        override fun onPause(owner: LifecycleOwner) {
            onPause()
        }

        override fun onResume(owner: LifecycleOwner) {
            onResume()
        }
    }

    init {
        lifecycleOwner.lifecycle.addObserver(lifecycleObserver)
    }

    open fun dispose() {
        lifecycleOwner.lifecycle.removeObserver(lifecycleObserver)
    }

    open fun onPause() {}

    open fun onResume() {}
}