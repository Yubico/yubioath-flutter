package com.yubico.authenticator.management

import com.yubico.authenticator.DialogIcon
import com.yubico.authenticator.DialogManager
import com.yubico.authenticator.DialogTitle
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

    suspend fun <T> useSession(
        actionDescription: ManagementActionDescription,
        action: (YubiKitManagementSession) -> T
    ): T {
        return deviceManager.withKey(
            onNfc = { useSessionNfc(actionDescription, action) },
            onUsb = { useSessionUsb(it, action) })
    }

    private suspend fun <T> useSessionUsb(
        device: UsbYubiKeyDevice,
        block: (YubiKitManagementSession) -> T
    ): T = device.withConnection<SmartCardConnection, T> {
        block(YubiKitManagementSession(it))
    }

    private suspend fun <T> useSessionNfc(
        actionDescription: ManagementActionDescription,
        block: (YubiKitManagementSession) -> T
    ): T {
        try {
            val result = suspendCoroutine { outer ->
                action = {
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
                    action?.invoke(Result.failure(CancellationException()))
                    action = null
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
        private val logger = LoggerFactory.getLogger(ManagementConnectionHelper::class.java)
    }
}