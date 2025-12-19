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
import com.yubico.authenticator.device.Info
import com.yubico.authenticator.device.unknownDeviceWithCapability
import com.yubico.authenticator.yubikit.DeviceInfoHelper.Companion.getDeviceInfo
import com.yubico.authenticator.yubikit.NfcState
import com.yubico.authenticator.yubikit.withConnection
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.util.Result
import com.yubico.yubikit.support.DeviceUtil
import kotlin.coroutines.cancellation.CancellationException
import kotlin.coroutines.suspendCoroutine
import org.slf4j.LoggerFactory

typealias YubiKitPivSession = com.yubico.yubikit.piv.PivSession

class PivConnectionHelper(private val deviceManager: DeviceManager) {
    private var pendingAction: PivAction? = null

    fun hasPending(): Boolean = pendingAction != null

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

    suspend fun <T : Any> useSmartCardConnection(
        onComplete: ((SmartCardConnection) -> Unit)? = null,
        waitForNfcKeyRemoval: Boolean = false,
        updateDeviceInfo: Boolean = false,
        block: (SmartCardConnection) -> T
    ): T {
        PivManager.updateDeviceInfo.set(updateDeviceInfo)
        NfcState.waitForNfcKeyRemoval = waitForNfcKeyRemoval
        return deviceManager.withKey(
            onUsb = { useSmartCardConnectionUsb(it, onComplete, updateDeviceInfo, block) },
            onNfc = { useSmartCardConnectionNfc(onComplete, block) },
            onCancelled = {
                pendingAction?.invoke(Result.failure(CancellationException()))
                pendingAction = null
            }
        )
    }

    suspend fun <T : Any> useSmartCardConnectionUsb(
        device: UsbYubiKeyDevice,
        onComplete: ((SmartCardConnection) -> Unit)? = null,
        updateDeviceInfo: Boolean,
        block: (SmartCardConnection) -> T
    ): T = device.withConnection<SmartCardConnection, T> { connection ->
        block(connection).also {
            onComplete?.invoke(connection)
            if (updateDeviceInfo) {
                val pid = device.pid
                runCatching {
                    deviceManager.setDeviceInfo(
                        runCatching {
                            val deviceInfo = DeviceUtil.readInfo(connection, pid)
                            val name = DeviceUtil.getName(deviceInfo, pid.type)
                            Info(name, false, pid.value, deviceInfo)
                        }.getOrNull()
                    )
                }
            }
        }
    }

    suspend fun <T : Any> useSmartCardConnectionNfc(
        onComplete: ((SmartCardConnection) -> Unit)? = null,
        block: (SmartCardConnection) -> T
    ): Result<T, Throwable> {
        try {
            val result = suspendCoroutine { outer ->
                pendingAction = {
                    outer.resumeWith(
                        runCatching {
                            val connection = it.value
                            block.invoke(connection).also {
                                onComplete?.invoke(connection)
                            }
                        }
                    )
                }
            }
            return Result.success(result)
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
