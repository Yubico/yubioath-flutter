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

import com.yubico.authenticator.DialogIcon
import com.yubico.authenticator.DialogManager
import com.yubico.authenticator.DialogTitle
import com.yubico.authenticator.MainViewModel
import com.yubico.authenticator.device.DeviceManager
import com.yubico.authenticator.fido.data.YubiKitFidoSession
import com.yubico.authenticator.yubikit.withConnection
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.fido.FidoConnection
import com.yubico.yubikit.core.util.Result
import org.slf4j.LoggerFactory
import kotlin.coroutines.cancellation.CancellationException
import kotlin.coroutines.suspendCoroutine

class FidoConnectionHelper(
    private val deviceManager: DeviceManager,
    private val dialogManager: DialogManager
) {
    private var pendingAction: FidoAction? = null

    fun invokePending(fidoSession: YubiKitFidoSession) {
        pendingAction?.let { action ->
            action.invoke(Result.success(fidoSession))
            pendingAction = null
        }
    }

    fun cancelPending() {
        pendingAction?.let { action ->
            action.invoke(Result.failure(CancellationException()))
            pendingAction = null
        }
    }

    suspend fun <T> useSession(
        actionDescription: FidoActionDescription,
        action: (YubiKitFidoSession) -> T
    ): T {
        return deviceManager.withKey(
            onNfc = { useSessionNfc(actionDescription,action) },
            onUsb = { useSessionUsb(it, action) })
    }

    suspend fun <T> useSessionUsb(
        device: UsbYubiKeyDevice,
        block: (YubiKitFidoSession) -> T
    ): T = device.withConnection<FidoConnection, T> {
        block(YubiKitFidoSession(it))
    }

    suspend fun <T> useSessionNfc(
        actionDescription: FidoActionDescription,
        block: (YubiKitFidoSession) -> T
    ): T {
        try {
            val result = suspendCoroutine { outer ->
                pendingAction = {
                    outer.resumeWith(runCatching {
                        block.invoke(it.value)
                    })
                }
                dialogManager.showDialog(
                    DialogIcon.Nfc,
                    DialogTitle.TapKey,
                    actionDescription.id
                ) {
                    logger.debug("Cancelled Dialog {}", actionDescription.name)
                    pendingAction?.invoke(Result.failure(CancellationException()))
                    pendingAction = null
                }
            }
            return result
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (error: Throwable) {
            throw error
        } finally {
            dialogManager.closeDialog()
        }
    }

    companion object {
        private val logger = LoggerFactory.getLogger(FidoConnectionHelper::class.java)
    }
}