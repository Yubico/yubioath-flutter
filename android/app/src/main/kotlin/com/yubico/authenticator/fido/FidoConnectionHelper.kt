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

package com.yubico.authenticator.fido

import com.yubico.authenticator.device.DeviceManager
import com.yubico.authenticator.fido.data.YubiKitFidoSession
import com.yubico.authenticator.yubikit.DeviceInfoHelper.Companion.getDeviceInfo
import com.yubico.authenticator.yubikit.withConnection
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.fido.FidoConnection
import com.yubico.yubikit.core.util.Result
import kotlin.coroutines.cancellation.CancellationException
import kotlin.coroutines.suspendCoroutine
import org.slf4j.LoggerFactory

class FidoConnectionHelper(private val deviceManager: DeviceManager) {
    private var pendingAction: FidoAction? = null

    fun hasPending(): Boolean = pendingAction != null

    fun invokePending(fidoSession: YubiKitFidoSession): Boolean {
        var requestHandled = true
        pendingAction?.let { action ->
            pendingAction = null
            // it is the pending action who handles this request
            requestHandled = false
            action.invoke(Result.success(fidoSession))
        }
        return requestHandled
    }

    fun cancelPending() {
        pendingAction?.let { action ->
            action.invoke(Result.failure(CancellationException()))
            pendingAction = null
        }
    }

    suspend fun <T> useSession(
        updateDeviceInfo: Boolean = false,
        block: (YubiKitFidoSession) -> T
    ): T {
        FidoManager.updateDeviceInfo.set(updateDeviceInfo)
        return deviceManager.withKey(
            onUsb = { useSessionUsb(it, updateDeviceInfo, block) },
            onNfc = { useSessionNfc(block) },
            onCancelled = {
                pendingAction?.invoke(Result.failure(CancellationException()))
                pendingAction = null
            }
        )
    }

    suspend fun <T> useSessionUsb(
        device: UsbYubiKeyDevice,
        updateDeviceInfo: Boolean = false,
        block: (YubiKitFidoSession) -> T
    ): T = device.withConnection<FidoConnection, T> {
        block(YubiKitFidoSession(it))
    }.also {
        if (updateDeviceInfo) {
            deviceManager.setDeviceInfo(runCatching { getDeviceInfo(device) }.getOrNull())
        }
    }

    suspend fun <T> useSessionNfc(block: (YubiKitFidoSession) -> T): Result<T, Throwable> {
        try {
            val result = suspendCoroutine { outer ->
                pendingAction = {
                    outer.resumeWith(
                        runCatching {
                            block.invoke(it.value)
                        }
                    )
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
        private val logger = LoggerFactory.getLogger(FidoConnectionHelper::class.java)
    }
}
