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

package com.yubico.authenticator.management

import com.yubico.authenticator.DialogManager
import com.yubico.authenticator.device.DeviceManager
import com.yubico.authenticator.yubikit.withConnection
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.util.Result
import org.slf4j.LoggerFactory
import kotlin.coroutines.cancellation.CancellationException
import kotlin.coroutines.suspendCoroutine

typealias YubiKitManagementSession = com.yubico.yubikit.management.ManagementSession
typealias ManagementAction = (Result<YubiKitManagementSession, Exception>) -> Unit

class ManagementConnectionHelper(
    private val deviceManager: DeviceManager,
    private val dialogManager: DialogManager
) {
    private var action: ManagementAction? = null

    suspend fun <T> useSession(action: (YubiKitManagementSession) -> T): T {
        return deviceManager.withKey(
            onNfc = { useSessionNfc(action) },
            onUsb = { useSessionUsb(it, action) })
    }

    private suspend fun <T> useSessionUsb(
        device: UsbYubiKeyDevice,
        block: (YubiKitManagementSession) -> T
    ): T = device.withConnection<SmartCardConnection, T> {
        block(YubiKitManagementSession(it))
    }

    private suspend fun <T> useSessionNfc(block: (YubiKitManagementSession) -> T): Result<T, Throwable> {
        try {
            val result = suspendCoroutine<T> { outer ->
                action = {
                    outer.resumeWith(runCatching {
                        block.invoke(it.value)
                    })
                }
                dialogManager.showDialog {
                    logger.debug("Cancelled Dialog")
                    action?.invoke(Result.failure(CancellationException()))
                    action = null
                }
            }
            return Result.success(result!!)
        } catch (cancelled: CancellationException) {
            return Result.failure(cancelled)
        } catch (error: Throwable) {
            return Result.failure(error)
        } finally {
            dialogManager.closeDialog()
        }
    }

    companion object {
        private val logger = LoggerFactory.getLogger(ManagementConnectionHelper::class.java)
    }
}