/*
 * Copyright (C) 2024-2025 Yubico.
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

package com.yubico.authenticator.management

import com.yubico.authenticator.device.DeviceManager
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.util.Result
import kotlin.coroutines.cancellation.CancellationException
import kotlin.coroutines.suspendCoroutine

typealias Action = (Result<YubiKeyDevice, Exception>) -> Unit

class ManagementConnectionHelper(private val deviceManager: DeviceManager) {
    private var pendingAction: Action? = null

    fun hasPending(): Boolean = pendingAction != null

    fun invokePending(device: YubiKeyDevice) {
        pendingAction?.let {
            pendingAction = null
            it.invoke(Result.success(device))
        }
    }

    fun cancelPending() {
        pendingAction?.let { it ->
            pendingAction = null
            it.invoke(Result.failure(CancellationException()))
        }
    }

    suspend fun <T : Any> useDevice(block: (YubiKeyDevice) -> T): T = deviceManager.withKey(
        onUsb = { useUsbDevice(it, block) },
        onNfc = { useNfcDevice(block) },
        onCancelled = {
            pendingAction?.let {
                pendingAction = null
                it.invoke(Result.failure(CancellationException()))
            }
        }
    )

    private suspend fun <T : Any> useUsbDevice(
        device: UsbYubiKeyDevice,
        block: suspend (YubiKeyDevice) -> T
    ): T = block(device)

    private suspend fun <T : Any> useNfcDevice(block: (YubiKeyDevice) -> T): Result<T, Throwable> {
        try {
            val result = suspendCoroutine<T> { outer ->
                pendingAction = {
                    outer.resumeWith(
                        runCatching {
                            block.invoke(it.value)
                        }
                    )
                }
            }
            return Result.success(result)
        } catch (cancelled: CancellationException) {
            return Result.failure(cancelled)
        } catch (error: Throwable) {
            return Result.failure(error)
        }
    }
}
