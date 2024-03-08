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
import com.yubico.authenticator.device.DeviceManager
import com.yubico.authenticator.fido.data.YubiKitFidoSession
import com.yubico.authenticator.yubikit.withConnection
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.fido.FidoConnection
import com.yubico.yubikit.core.util.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.slf4j.LoggerFactory
import java.io.IOException
import kotlin.coroutines.cancellation.CancellationException
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class FidoConnectionHelper(
    private val deviceManager: DeviceManager,
    private val dialogManager: DialogManager,
    private val coroutineScope: CoroutineScope
) {
    private var pendingAction: FidoAction? = null

    fun invokePending(fidoSession: YubiKitFidoSession) {
        pendingAction?.let { action ->
            action.invoke(Result.success(fidoSession))
            pendingAction = null
        }
    }

    private suspend fun updateDialogAfterFailure(actionDescription: FidoActionDescription,) {
        suspendCoroutine {
            coroutineScope.launch {
                dialogManager.updateDialogState(
                    DialogIcon.Failure,
                    DialogTitle.OperationFailed,
                    actionDescription.id
                )
                delay(1000)
                dialogManager.updateDialogState(
                    DialogIcon.Nfc,
                    DialogTitle.TapKey,
                    actionDescription.id
                )
                logger.debug("Resuming")
                it.resume(Unit)
            }
        }
    }

    private var waitingForNfcTap = false

    fun isWaitingForNfcTap() : Boolean {
        return waitingForNfcTap
    }

    fun cancelCurrent() {
        waitingForNfcTap = false
        coroutineScope.launch {
            dialogManager.closeDialog()
        }

    }

    suspend fun <T> useSession(
        actionDescription: FidoActionDescription,
        action: (YubiKitFidoSession) -> T
    ): T {
        var dialogShown = false
        while (true) {
            try {
                return deviceManager.withKey(
                    onNfc = {
                        if (!dialogShown) {
                            waitingForNfcTap = true
                            dialogManager.showDialog(
                                DialogIcon.Nfc,
                                DialogTitle.TapKey,
                                actionDescription.id
                            ) {
                                logger.debug("Cancelled Dialog {}", actionDescription.name)
                                pendingAction?.invoke(Result.failure(CancellationException()))
                                pendingAction = null
                            }
                            dialogShown = true
                        }
                        val result = useSessionNfc(actionDescription, action)
                        dialogManager.closeDialog()
                        waitingForNfcTap = false
                        result
                    },
                    onUsb = {
                        dialogManager.closeDialog()
                        useSessionUsb(it, action)
                    }
                )
            } catch(ioException: IOException) {
                logger.error("Caught IO exception: ", ioException)
                updateDialogAfterFailure(actionDescription)
            } catch(exception: Exception) {
                logger.error("Caught Exception: ", exception)
                waitingForNfcTap = false
                dialogManager.closeDialog()
            }
        }
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
            }
            return result
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (error: Throwable) {
            logger.error("Error when dialog shown: ", error)
            throw error
        }
    }

    companion object {
        private val logger = LoggerFactory.getLogger(FidoConnectionHelper::class.java)
    }
}