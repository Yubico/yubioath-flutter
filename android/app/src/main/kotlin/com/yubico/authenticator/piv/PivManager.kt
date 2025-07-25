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

import androidx.lifecycle.LifecycleOwner
import com.yubico.authenticator.AppContextManager
import com.yubico.authenticator.MainActivity
import com.yubico.authenticator.MainViewModel
import com.yubico.authenticator.NfcOverlayManager
import com.yubico.authenticator.OperationContext
import com.yubico.authenticator.device.DeviceManager
import com.yubico.authenticator.piv.data.CertInfo
import com.yubico.authenticator.piv.data.PivSlot
import com.yubico.authenticator.piv.data.PivState
import com.yubico.authenticator.piv.data.SlotMetadata
import com.yubico.authenticator.piv.data.hexStringToByteArray
import com.yubico.authenticator.setHandler
import com.yubico.authenticator.yubikit.DeviceInfoHelper.Companion.getDeviceInfo
import com.yubico.authenticator.yubikit.withConnection
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.core.YubiKeyConnection
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.application.BadResponseException
import com.yubico.yubikit.core.smartcard.ApduException
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.util.Result
import com.yubico.yubikit.piv.ManagementKeyType
import com.yubico.yubikit.piv.ObjectId
import com.yubico.yubikit.piv.Slot
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.slf4j.LoggerFactory
import java.io.IOException
import java.util.Arrays
import java.util.concurrent.atomic.AtomicBoolean

typealias PivAction = (Result<YubiKitPivSession, Exception>) -> Unit

class PivManager(
    messenger: BinaryMessenger,
    deviceManager: DeviceManager,
    lifecycleOwner: LifecycleOwner,
    appMethodChannel: MainActivity.AppMethodChannel,
    nfcOverlayManager: NfcOverlayManager,
    private val pivViewModel: PivViewModel,
    mainViewModel: MainViewModel
) : AppContextManager(deviceManager) {

    companion object {
        val updateDeviceInfo = AtomicBoolean(false)
    }

    private val connectionHelper = PivConnectionHelper(deviceManager)

    private val pivChannel = MethodChannel(messenger, "android.piv.methods")

    private val logger = LoggerFactory.getLogger(PivManager::class.java)

    private var pinRetries: Int? = null

    init {
        logger.debug("PivManager initialized")
        pinRetries = null

        pivChannel.setHandler(coroutineScope) { method, args ->
            when (method) {

                "reset" -> reset()

                "authenticate" -> authenticate(
                    (args["managementKey"] as String).hexStringToByteArray()
                )

                "verifyPin" -> verifyPin(
                    (args["pin"] as String).toCharArray()
                )

                "changePin" -> changePin(
                    (args["pin"] as String).toCharArray(),
                    (args["newPin"] as String).toCharArray(),
                )

                "changePuk" -> changePuk(
                    (args["puk"] as String).toCharArray(),
                    (args["newPuk"] as String).toCharArray(),
                )

                "setManagementKey" -> setManagementKey(
                    (args["key"] as String).hexStringToByteArray(),
                    args["keyType"] as ManagementKeyType,
                    args["storeKey"] as Boolean
                )

                "unblockPin" -> unblockPin(
                    (args["puk"] as String).toCharArray(),
                    (args["newPin"] as String).toCharArray(),
                )

                "delete" -> delete(
                    Slot.fromStringAlias(args["slot"] as String),
                    (args["deleteCert"] as Boolean),
                    (args["deleteKey"] as Boolean),
                )

                "moveKey" -> moveKey(
                    Slot.fromStringAlias(args["slot"] as String),
                    Slot.fromStringAlias(args["destination"] as String),
                    (args["overwriteKey"] as Boolean),
                    (args["includeCertificate"] as Boolean),
                )

                "examineFile" -> examineFile(
                    (args["slot"] as String),
                    (args["data"] as String),
                    (args["password"] as String),
                )

                "validateRfc4514" -> validateRfc4514(
                    (args["data"] as String),
                )

                "importFile" -> importFile(
                    (args["slot"] as String),
                    (args["data"] as String),
                    (args["password"] as String),
                    (args["pinPolicy"] as Int),
                    (args["touchPolicy"] as Int),
                )

                "getSlot" -> getSlot(
                    (args["slot"] as String),
                )

                else -> throw NotImplementedError()
            }
        }
    }

    override fun supports(appContext: OperationContext): Boolean = when (appContext) {
        OperationContext.Piv -> true
        else -> false
    }

    override fun activate() {
        super.activate()
        logger.debug("PivManager activated")
    }

    override fun deactivate() {
        pivViewModel.clearState()
        pivViewModel.updateSlots(null)
        connectionHelper.cancelPending()
        logger.debug("PivManager deactivated")
        super.deactivate()
    }

    override fun onError(e: Exception) {
        super.onError(e)
        if (connectionHelper.hasPending()) {
            logger.error("Cancelling pending action. Cause: ", e)
            connectionHelper.cancelPending()
        }
    }

    override fun hasPending(): Boolean {
        return connectionHelper.hasPending()
    }

    override fun dispose() {
        super.dispose()
        pivChannel.setMethodCallHandler(null)
        logger.debug("PivManager disposed")
    }

    override suspend fun processYubiKey(device: YubiKeyDevice): Boolean {
        var requestHandled = true
        try {
            device.withConnection<SmartCardConnection, Unit> { connection ->
                requestHandled = processYubiKey(connection, device)
            }

            if (updateDeviceInfo.getAndSet(false)) {
                deviceManager.setDeviceInfo(runCatching { getDeviceInfo(device) }.getOrNull())
            }
        } catch (e: Exception) {

            logger.error("Cancelling pending action. Cause: ", e)
            connectionHelper.cancelPending()

            if (e !is IOException) {
                // we don't clear the session on IOExceptions so that the session is ready for
                // a possible re-run of a failed action.
                pivViewModel.clearState()
            }
            throw e
        }

        return requestHandled
    }

    private fun processYubiKey(connection: YubiKeyConnection, device: YubiKeyDevice): Boolean {
        var requestHandled = true
        val piv = YubiKitPivSession(connection as SmartCardConnection)

        val previousSerial = pivViewModel.currentSerial
        val currentSerial = piv.serialNumber
        pivViewModel.setSerial(currentSerial)
        logger.debug(
            "Previous serial: {}, current serial: {}",
            previousSerial.value,
            currentSerial
        )

        val sameDevice = previousSerial.value == currentSerial

        if (device is NfcYubiKeyDevice && sameDevice) {
            requestHandled = connectionHelper.invokePending(piv)
        } else {

            if (!sameDevice) {
                // different key
                logger.debug("This is a different key than previous, invalidating the PIN token")
                connectionHelper.cancelPending()
            }
            pivViewModel.setState(
                PivState(
                    piv,
                    authenticated = false,
                    derivedKey = false,
                    storedKey = false,
                    supportsBio = false
                )
            )
        }

        pivViewModel.updateSlots(getSlots(piv));

        return requestHandled
    }

    private suspend fun reset(): String =
        connectionHelper.useSession { piv ->
            piv.reset()
            ""
        }

    private suspend fun authenticate(managementKey: ByteArray): String =
        connectionHelper.useSession { piv ->
            piv.authenticate(managementKey)
            ""
        }

    private suspend fun verifyPin(pin: CharArray): String =
        connectionHelper.useSession { piv ->
            piv.verifyPin(pin)
            ""
        }

    private suspend fun changePin(pin: CharArray, newPin: CharArray): String =
        connectionHelper.useSession(updateDeviceInfo = true) { piv ->
            try {
                piv.changePin(pin, newPin)
                ""
            } finally {
                Arrays.fill(newPin, 0.toChar())
                Arrays.fill(pin, 0.toChar())
            }
        }

    private suspend fun changePuk(puk: CharArray, newPuk: CharArray): String =
        connectionHelper.useSession(updateDeviceInfo = true) { piv ->
            try {
                piv.changePuk(puk, newPuk)
                ""
            } finally {
                Arrays.fill(newPuk, 0.toChar())
                Arrays.fill(puk, 0.toChar())
            }
        }

    private suspend fun setManagementKey(
        managementKey: ByteArray,
        keyType: ManagementKeyType,
        storeKey: Boolean
    ): String =
        connectionHelper.useSession(updateDeviceInfo = true) { piv ->
            piv.setManagementKey(keyType, managementKey, false) // review require touch
            ""
        }

    private suspend fun unblockPin(puk: CharArray, newPin: CharArray): String =
        connectionHelper.useSession(updateDeviceInfo = true) { piv ->
            try {
                piv.unblockPin(puk, newPin)
                ""
            } finally {
                Arrays.fill(newPin, 0.toChar())
                Arrays.fill(puk, 0.toChar())
            }
        }

    private fun getSlots(piv: YubiKitPivSession): List<PivSlot> =
        try {
            val supportsMetadata = piv.supports(YubiKitPivSession.FEATURE_METADATA)
            pivViewModel.updateSlots(null)

            val slotList = Slot.entries.minus(Slot.ATTESTATION).map {
                val metadata = if (supportsMetadata) {
                    runPivOperation { piv.getSlotMetadata(it) }
                } else null
                val certificate = runPivOperation { piv.getCertificate(it) }

                PivSlot(
                    it.value,
                    metadata?.let(::SlotMetadata),
                    certificate?.let(::CertInfo),
                    null
                )
            }

            slotList
        } finally {

        }

    private suspend fun delete(slot: Slot, deleteCert: Boolean, deleteKey: Boolean): String =
        connectionHelper.useSession(updateDeviceInfo = true) { piv ->
            try {
                if (!deleteCert && !deleteKey) {
                    throw IllegalArgumentException("Missing delete option")
                }

                if (deleteCert) {
                    piv.deleteCertificate(slot)
                    piv.putObject(ObjectId.CHUID, generateChuid())
                }

                if (deleteKey) {
                    piv.deleteKey(slot)
                }
                ""
            } finally {
            }
        }

    private suspend fun moveKey(
        src: Slot,
        dst: Slot,
        overwriteKey: Boolean,
        includeCertificate: Boolean
    ): String =
        connectionHelper.useSession(updateDeviceInfo = true) { piv ->
            try {

                val sourceObject = if (includeCertificate) {
                    piv.getObject(src.objectId)
                } else null

                if (overwriteKey) {
                    piv.deleteKey(dst)
                }

                piv.moveKey(src, dst)

                sourceObject?.let {
                    piv.putObject(dst.objectId, it)
                    piv.deleteCertificate(src)
                    piv.putObject(ObjectId.CHUID, generateChuid())
                }
                ""
            } finally {
            }
        }

    private fun generateChuid(): ByteArray {
        // TODO
        return ByteArray(10)
    }

    private suspend fun examineFile(
        slot: String,
        data: String,
        password: String
    ): String =
        connectionHelper.useSession(updateDeviceInfo = true) { piv ->
            try {
                ""
            } finally {
            }
        }

    private suspend fun validateRfc4514(
        data: String
    ): String =
        connectionHelper.useSession(updateDeviceInfo = true) { piv ->
            try {
                ""
            } finally {
            }
        }


    private suspend fun importFile(
        slot: String,
        data: String,
        password: String,
        pinPolicy: Int,
        touchPolicy: Int
    ): String =
        connectionHelper.useSession(updateDeviceInfo = true) { piv ->
            try {
                ""
            } finally {
            }
        }

    private suspend fun getSlot(
        slot: String
    ): String =
        connectionHelper.useSession(updateDeviceInfo = true) { piv ->
            try {
                ""
            } finally {
            }
        }

    override fun onDisconnected() {
    }

    override fun onTimeout() {
        pivViewModel.clearState()
    }

    /**
     * Executes a PIV operation and returns null if it fails with a known,
     * recoverable exception. Other exceptions are re-thrown.
     */
    private fun <T> runPivOperation(operation: () -> T): T? {
        return try {
            operation()
        } catch (e: Exception) {
            when (e) {
                is ApduException, is BadResponseException -> null
                else -> throw e
            }
        }
    }
}