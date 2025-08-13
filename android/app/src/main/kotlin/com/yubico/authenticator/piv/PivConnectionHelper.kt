/*
 * Copyright (C) 2025 Yubico.
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

package com.yubico.authenticator.piv

import com.yubico.authenticator.device.DeviceManager
import com.yubico.authenticator.yubikit.withConnection
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.util.Result
import org.slf4j.LoggerFactory
import kotlin.coroutines.cancellation.CancellationException
import kotlin.coroutines.suspendCoroutine

typealias YubiKitPivSession = com.yubico.yubikit.piv.PivSession

class PivConnectionHelper(private val deviceManager: DeviceManager) {
    private var pendingAction: PivAction? = null

    fun hasPending(): Boolean {
        return pendingAction != null
    }

    fun invokePending(piv: SmartCardConnection): Boolean {
        var requestHandled = true
        pendingAction?.let { action ->
            pendingAction = null
            // it is the pending action who handles this request
            requestHandled = false
            action.invoke(Result.success(piv))
        }
        return requestHandled
    }

    fun cancelPending() {
        pendingAction?.let { action ->
            action.invoke(Result.failure(CancellationException()))
            pendingAction = null
        }
    }

    suspend fun <T> useSmartCardConnection(
        block: (SmartCardConnection) -> T
    ): T {
        return deviceManager.withKey(
            onUsb = { useSmartCardConnectionUsb(it, block) },
            onNfc = { useSmartCardConnectionNfc(block) },
            onCancelled = {
                pendingAction?.invoke(Result.failure(CancellationException()))
                pendingAction = null
            }
        )
    }

    suspend fun <T> useSmartCardConnectionUsb(
        device: UsbYubiKeyDevice,
        block: (SmartCardConnection) -> T
    ): T = device.withConnection<SmartCardConnection, T> {
        block(it)
    }

    suspend fun <T> useSmartCardConnectionNfc(
        block: (SmartCardConnection) -> T
    ): Result<T, Throwable> {
        try {
            val result = suspendCoroutine { outer ->
                pendingAction = {
                    outer.resumeWith(runCatching {
                        block.invoke(it.value)
                    })
                }
            }
            return Result.success(result!!)
        } catch (cancelled: CancellationException) {
            return Result.failure(cancelled)
        } catch (error: Throwable) {
            logger.error("Exception during action: ", error)
            return Result.failure(error)
        }
    }

    companion object {
        private val logger = LoggerFactory.getLogger(PivConnectionHelper::class.java)
    }
}