/*
 * Copyright (C) 2024 Yubico.
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
import com.yubico.authenticator.device.Info
import com.yubico.authenticator.fido.data.YubiKitFidoSession
import com.yubico.authenticator.yubikit.DeviceInfoHelper.Companion.getDeviceInfo
import com.yubico.authenticator.yubikit.withConnection
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.fido.FidoConnection
import com.yubico.yubikit.core.util.Result
import org.slf4j.LoggerFactory
import java.util.Timer
import java.util.TimerTask
import kotlin.coroutines.cancellation.CancellationException
import kotlin.coroutines.suspendCoroutine
import kotlin.concurrent.schedule

class FidoConnectionHelper(private val deviceManager: DeviceManager) {
    private var pendingAction: FidoAction? = null
    private var deviceInfoTimer: TimerTask? = null

    fun invokePending(fidoSession: YubiKitFidoSession) {
        pendingAction?.let { action ->
            action.invoke(Result.success(fidoSession))
            pendingAction = null
        }
    }

    fun cancelPending() {
        deviceInfoTimer?.cancel()
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
            onDialogCancelled = {
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
            scheduleDeviceInfoUpdate(getDeviceInfo(device))
        }
    }

    suspend fun <T> useSessionNfc(
        block: (YubiKitFidoSession) -> T
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

    fun scheduleDeviceInfoUpdate(deviceInfo: Info?) {
        deviceInfoTimer?.cancel()
        deviceInfoTimer = Timer("update-device-info", false).schedule(500) {
            logger.debug("Updating device info")
            deviceManager.setDeviceInfo(deviceInfo)
        }
    }

    companion object {
        private val logger = LoggerFactory.getLogger(FidoConnectionHelper::class.java)
    }
}