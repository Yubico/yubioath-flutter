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
import com.yubico.authenticator.jsonSerializer
import com.yubico.authenticator.piv.data.CertInfo
import com.yubico.authenticator.piv.data.PivSlot
import com.yubico.authenticator.piv.data.PivState
import com.yubico.authenticator.piv.data.SlotMetadata
import com.yubico.authenticator.piv.data.byteArrayToHexString
import com.yubico.authenticator.piv.data.fingerprint
import com.yubico.authenticator.piv.data.hexStringToByteArray
import com.yubico.authenticator.piv.data.isoFormat
import com.yubico.authenticator.piv.KeyMaterialParser.getLeafCertificates
import com.yubico.authenticator.piv.KeyMaterialParser.parse
import com.yubico.authenticator.piv.KeyMaterialParser.toPem
import com.yubico.authenticator.setHandler
import com.yubico.authenticator.yubikit.DeviceInfoHelper.Companion.getDeviceInfo
import com.yubico.authenticator.yubikit.withConnection
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.core.YubiKeyConnection
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.application.BadResponseException
import com.yubico.yubikit.core.application.InvalidPinException
import com.yubico.yubikit.core.keys.PrivateKeyValues
import com.yubico.yubikit.core.keys.PublicKeyValues
import com.yubico.yubikit.core.smartcard.ApduException
import com.yubico.yubikit.core.smartcard.SW
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.util.Result
import com.yubico.yubikit.piv.KeyType
import com.yubico.yubikit.piv.ManagementKeyType
import com.yubico.yubikit.piv.ObjectId
import com.yubico.yubikit.piv.PinPolicy
import com.yubico.yubikit.piv.PivSession
import com.yubico.yubikit.piv.Slot
import com.yubico.yubikit.piv.TouchPolicy
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import org.bouncycastle.asn1.x500.X500Name
import org.slf4j.LoggerFactory
import java.io.IOException
import java.security.cert.X509Certificate
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

    private val managementKeyStorage: MutableMap<String, ByteArray> = mutableMapOf()
    private val pinStorage: MutableMap<String, CharArray> = mutableMapOf()

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
                    (args["key"] as String).hexStringToByteArray()
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
                    (args["password"] as String?),
                )

                "validateRfc4514" -> validateRfc4514(
                    (args["data"] as String),
                )

                "generate" -> generate(
                    (args["slot"] as String),
                    (args["keyType"] as Int),
                    (args["pinPolicy"] as Int),
                    (args["touchPolicy"] as Int),
                    (args["subject"] as String?),
                    (args["generateType"] as String),
                    (args["validFrom"] as String?),
                    (args["validTo"] as String?)
                )

                "importFile" -> importFile(
                    Slot.fromStringAlias(args["slot"] as String),
                    (args["data"] as String),
                    (args["password"] as String?),
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

        pivViewModel.updateSlots(getSlots(piv))

        return requestHandled
    }

    private suspend fun reset(): String =
        connectionHelper.useSession { piv ->
            piv.reset()
            ""
        }


    private fun doAuth(piv: PivSession, serial: String) =
        try {
            val managementKey = managementKeyStorage[serial]
                ?: "010203040506070801020304050607080102030405060708".hexStringToByteArray()
            piv.authenticate(managementKey)
        } catch (e: Exception) {
            managementKeyStorage.remove(serial)
            throw e
        }

    private suspend fun authenticate(managementKey: ByteArray): String =
        connectionHelper.useSession { piv ->
            try {
                val serial = pivViewModel.currentSerial.value.toString()
                managementKeyStorage[serial] = managementKey
                doAuth(piv, serial)
                jsonSerializer.encodeToString(mapOf("status" to true))
            } catch (_: Exception) {
                jsonSerializer.encodeToString(mapOf("status" to false))
            }
        }

    private fun doVerifyPin(piv: PivSession, serial: String) =
        try {
            pinStorage[serial]?.let { piv.verifyPin(it) }
        } catch (e: Exception) {
            pinStorage.remove(serial)
            throw e
        }

    private suspend fun verifyPin(pin: CharArray): String =
        connectionHelper.useSession { piv ->
            try {
                val serial = pivViewModel.currentSerial.value.toString()
                pinStorage[serial] = pin.clone()
                handlePinPukErrors { doVerifyPin(piv, serial) }
            } finally {
                Arrays.fill(pin, 0.toChar())
            }
        }

    private suspend fun changePin(pin: CharArray, newPin: CharArray): String =
        connectionHelper.useSession(updateDeviceInfo = true) { piv ->
            try {
                handlePinPukErrors { piv.changePin(pin, newPin) }
            } finally {
                Arrays.fill(newPin, 0.toChar())
                Arrays.fill(pin, 0.toChar())
            }
        }

    private suspend fun changePuk(puk: CharArray, newPuk: CharArray): String =
        connectionHelper.useSession(updateDeviceInfo = true) { piv ->
            try {
                handlePinPukErrors { piv.changePuk(puk, newPuk) }
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
                handlePinPukErrors { piv.unblockPin(puk, newPin) }
            } finally {
                Arrays.fill(newPin, 0.toChar())
                Arrays.fill(puk, 0.toChar())
            }
        }

    private fun handlePinPukErrors(block: () -> Unit) : String {
        try {
            block()
            return jsonSerializer.encodeToString(mapOf("status" to "success"))
        } catch (invalidPin: InvalidPinException) {
            return jsonSerializer.encodeToString(mapOf("status" to "invalid-pin",
                "attemptsRemaining" to invalidPin.attemptsRemaining))
        } catch (apduException: ApduException) {
            if (apduException.sw == SW.CONDITIONS_NOT_SATISFIED) {
                return jsonSerializer.encodeToString(mapOf("status" to "pin-complexity"))
            }
        }
        return jsonSerializer.encodeToString(mapOf("status" to "other-error"))
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
                doAuth(piv, pivViewModel.currentSerial.value.toString())

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

                doAuth(piv, pivViewModel.currentSerial.value.toString())

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

    private fun chooseCertificate(certificates: List<X509Certificate>?): X509Certificate? {
        return certificates?.let {
            when {
                it.size > 1 -> getLeafCertificates(it).firstOrNull()
                else -> it.firstOrNull()
            }
        }
    }

    private fun getCertificateInfo(certificate: X509Certificate?) =
        certificate?.let {
            buildJsonObject {
                val keyType = KeyType.fromKey(certificate.publicKey)
                put("key_type", JsonPrimitive(keyType.value.toInt() and 0xff))
                put("subject", JsonPrimitive(certificate.subjectDN.name))
                put("issuer", JsonPrimitive(certificate.issuerDN.name))
                put("serial", JsonPrimitive(certificate.serialNumber.toString()))
                put("not_valid_before", JsonPrimitive(certificate.notBefore.isoFormat()))
                put("not_valid_after", JsonPrimitive(certificate.notAfter.isoFormat()))
                put("fingerprint", JsonPrimitive(certificate.fingerprint()))
            }
        }

    private fun publicKeyMatch(certificate: X509Certificate?, metadata: SlotMetadata?) : Boolean? {
        if (certificate == null || metadata == null) {
            return null
        }

        val slotPublicKey = metadata.publicKey
        val certPublicKey = PublicKeyValues.fromPublicKey(certificate.publicKey)

        return slotPublicKey?.encoded.contentEquals(certPublicKey.encoded)
    }

    private fun examineFile(
        slot: String,
        data: String,
        password: String?
    ): String = try {
        val (certificates, privateKey) = parseFile(data, password)
        val certificate = chooseCertificate(certificates)

        val result = buildJsonObject {
            put("status", JsonPrimitive(true))
            put("password", JsonPrimitive(password != null))
            put("key_type", privateKey?.let {
                JsonPrimitive(
                    KeyType.fromKeyParams(
                        PrivateKeyValues.fromPrivateKey(it)
                    ).value.toUByte())
            } ?: JsonNull)
            put("cert_info", getCertificateInfo(certificate) ?: JsonNull)
            pivViewModel.getMetadata(slot)?.let {
                if (certificate != null && privateKey == null) {
                    put("public_key_match", JsonPrimitive(publicKeyMatch(certificate, it)))
                }
            }
        }

        jsonSerializer.encodeToString(JsonObject.serializer(), result)
    } catch (_: InvalidPasswordException) {
        val result = buildJsonObject {
            put("status", JsonPrimitive(false))
        }
        jsonSerializer.encodeToString(JsonObject.serializer(), result)
    } finally {
    }


    private fun getX500Name(data: String) = X500Name(data)


    private fun validateRfc4514(
        data: String
    ): String = try {
        getX500Name(data)
        jsonSerializer.encodeToString(mapOf("status" to true))
    } catch (_: IllegalArgumentException) {
        jsonSerializer.encodeToString(mapOf("status" to false))
    }

    private suspend fun generate(
        slot: String,
        keyType: Int,
        pinPolicy: Int,
        touchPolicy: Int,
        subject: String?,
        generateType: String,
        validFrom: String?,
        validTo: String?
    ): String =
        connectionHelper.useSession(updateDeviceInfo = true) { piv ->
            try {

                val serial = pivViewModel.currentSerial.value.toString()
                doAuth(piv, serial)
                doVerifyPin(piv, serial)

                val keyValues = piv.generateKeyValues(
                    Slot.fromStringAlias(slot),
                    KeyType.fromValue(keyType),
                    PinPolicy.fromValue(pinPolicy),
                    TouchPolicy.fromValue(touchPolicy)
                )

                val publicKey = keyValues.toPublicKey()
                val publicKeyPem = publicKey.encoded

                val result = when (generateType) {
                    "publicKey" -> publicKeyPem.byteArrayToHexString()
                    "csr" -> {
                        if (subject == null) {
                            throw IllegalArgumentException("Subject missing for csr")
                        }
                        // TODO implement
                        //val csrBuilder = JcaPKCS10CertificationRequestBuilder(getX500Name(subject), publicKey)
                        //val csBuilder = JcaContentSignerBuilder("SHA256withRSA")
                        //
                        //val signer = csBuilder.build(keyPair.getPrivate());
                        //csrBuilder.build(signer)
                        ""
                    }

                    "certificate" -> "" // TODO implement
                    else -> throw IllegalArgumentException("Invalid generate type: $generateType")
                }

                jsonSerializer.encodeToString(
                    mapOf(
                        "public_key" to publicKeyPem.byteArrayToHexString(),
                        "result" to result
                    )
                )
            } catch (e: Exception) {
                throw e
            } finally {

            }
        }

    private fun parseFile(
        data: String,
        password: String?
    ): KeyMaterial = try {
            parse(data.hexStringToByteArray(), password?.toCharArray())
        } catch (e: Exception) {
            when (e) {
                is IllegalArgumentException, is IOException -> KeyMaterial(
                    emptyList(),
                    null
                )

                else -> throw e
            }
        }


    private suspend fun importFile(
        slot: Slot,
        data: String,
        password: String?,
        pinPolicy: Int,
        touchPolicy: Int
    ): String =
        connectionHelper.useSession(updateDeviceInfo = true) { piv ->
            try {

                val serial = pivViewModel.currentSerial.value.toString()
                doAuth(piv, serial)

                val (certificates, privateKey) = parseFile(data, password)
                // TODO catch invalid password exception

                if (privateKey == null && certificates.isEmpty()) {
                    throw IllegalArgumentException("Failed to parse")
                }

                var metadata : SlotMetadata? = null
                privateKey?.let {
                    piv.putKey(
                        slot,
                        PrivateKeyValues.fromPrivateKey(privateKey),
                        PinPolicy.fromValue(pinPolicy),
                        TouchPolicy.fromValue(touchPolicy)
                    )

                    metadata = try {
                         SlotMetadata(piv.getSlotMetadata(slot))
                    } catch (e: Exception) {
                        when (e) {
                            // TODO NotSupported
                            is ApduException, is BadResponseException -> null
                            else -> throw e
                        }
                    }
                }

                val certificate = chooseCertificate(certificates)
                certificate?.let {
                    piv.putCertificate(slot, certificate)
                    piv.putObject(ObjectId.CHUID, generateChuid())
                    // TODO self.certificate = certificate
                }

                val result = buildJsonObject {

                    // TODO get public key from the private key
                    val publicKey2 = metadata?.let {
                        it.publicKey?.toPublicKey()
                    }
                    put("metadata", metadata?.let {buildJsonObject {
                        put("key_type", JsonPrimitive(it.keyType.toInt()))
                        put("pin_policy", JsonPrimitive(it.pinPolicy))
                        put("touch_policy", JsonPrimitive(it.touchPolicy))
                        put("generated", JsonPrimitive(it.generated))
                        put(
                            "public_key",
                            it.publicKey?.let { JsonPrimitive(it.toPublicKey().toPem()) }
                                ?: JsonNull)
                    }} ?: JsonNull)
                    put("public_key", privateKey?.let {
                        JsonPrimitive(publicKey2?.toPem())} ?: JsonNull)
                    put("certificate",
                        certificate?.let {
                            JsonPrimitive(it.encoded.byteArrayToHexString())
                        } ?: JsonNull
                    )
                }

                jsonSerializer.encodeToString(JsonObject.serializer(), result)
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