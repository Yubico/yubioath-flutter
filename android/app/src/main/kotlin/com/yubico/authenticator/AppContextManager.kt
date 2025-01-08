/*
 * Copyright (C) 2022-2025 Yubico.
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

import com.yubico.authenticator.device.DeviceListener
import com.yubico.authenticator.device.DeviceManager
import com.yubico.yubikit.core.YubiKeyDevice
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.cancel
import java.util.concurrent.Executors

/**
 * Provides behavior to run when a YubiKey is inserted/tapped for a specific view of the app.
 */
abstract class AppContextManager(
    protected val deviceManager: DeviceManager
) : DeviceListener {

    private val dispatcher = Executors.newSingleThreadExecutor().asCoroutineDispatcher()
    protected val coroutineScope = CoroutineScope(SupervisorJob() + dispatcher)

    abstract suspend fun processYubiKey(device: YubiKeyDevice): Boolean

    open fun activate() {
        deviceManager.addDeviceListener(this)
    }

    open fun deactivate() {
        deviceManager.removeDeviceListener(this)
    }

    open fun dispose() {
        coroutineScope.cancel()
    }

    open fun onPause() {}

    open fun onError(e: Exception) {}

    abstract fun hasPending() : Boolean
}

class ContextDisposedException : Exception()