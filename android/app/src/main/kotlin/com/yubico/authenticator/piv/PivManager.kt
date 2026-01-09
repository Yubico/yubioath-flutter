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

import com.yubico.authenticator.AppContextManager
import com.yubico.authenticator.OperationContext
import com.yubico.authenticator.device.DeviceManager
import com.yubico.authenticator.piv.KeyMaterialParser.getLeafCertificates
import com.yubico.authenticator.piv.KeyMaterialParser.parse
import com.yubico.authenticator.piv.KeyMaterialParser.toPem
import com.yubico.authenticator.piv.data.ManagementKeyMetadata
import com.yubico.authenticator.piv.data.PinMetadata
import com.yubico.authenticator.piv.data.PivSlot
import com.yubico.authenticator.piv.data.PivState
import com.yubico.authenticator.piv.data.PivStateMetadata
import com.yubico.authenticator.piv.data.PivmanData
import com.yubico.authenticator.piv.data.SlotMetadata
import com.yubico.authenticator.piv.data.fingerprint
import com.yubico.authenticator.piv.data.isoFormat
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
import com.yubico.yubikit.core.util.Tlv
import com.yubico.yubikit.core.util.Tlvs
import com.yubico.yubikit.management.Capability
import com.yubico.yubikit.piv.KeyType
import com.yubico.yubikit.piv.ManagementKeyType
import com.yubico.yubikit.piv.ObjectId
import com.yubico.yubikit.piv.PinPolicy
import com.yubico.yubikit.piv.PivSession
import com.yubico.yubikit.piv.PivSession.FEATURE_METADATA
import com.yubico.yubikit.piv.PivSession.FEATURE_SERIAL
import com.yubico.yubikit.piv.Slot
import com.yubico.yubikit.piv.TouchPolicy
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.nio.charset.StandardCharsets
import java.security.SecureRandom
import java.security.cert.X509Certificate
import java.text.SimpleDateFormat
import java.util.Arrays
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.atomic.AtomicBoolean
import org.bouncycastle.asn1.x500.X500Name
import org.json.JSONObject
import org.slf4j.LoggerFactory

typealias PivAction = (Result<SmartCardConnection, Exception>) -> Unit

class PivManager(
    messenger: BinaryMessenger,
    deviceManager: DeviceManager,
    private val pivViewModel: PivViewModel
) : AppContextManager(deviceManager) {

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
                    (args["key"] as String).hexToByteArray()
                )

                "verifyPin" -> verifyPin(
                    (args["pin"] as String).toCharArray()
                )

                "changePin" -> changePin(
                    (args["pin"] as String).toCharArray(),
                    (args["newPin"] as String).toCharArray()
                )

                "changePuk" -> changePuk(
                    (args["puk"] as String).toCharArray(),
                    (args["newPuk"] as String).toCharArray()
                )

                "setManagementKey" -> setManagementKey(
                    (args["key"] as String).hexToByteArray(),
                    ManagementKeyType.fromValue((args["keyType"] as Integer).toByte()),
                    args["storeKey"] as Boolean
                )

                "unblockPin" -> unblockPin(
                    (args["puk"] as String).toCharArray(),
                    (args["newPin"] as String).toCharArray()
                )

                "delete" -> delete(
                    Slot.fromStringAlias(args["slot"] as String),
                    (args["deleteCert"] as Boolean),
                    (args["deleteKey"] as Boolean)
                )

                "moveKey" -> moveKey(
                    Slot.fromStringAlias(args["slot"] as String),
                    Slot.fromStringAlias(args["destination"] as String),
                    (args["overwriteKey"] as Boolean),
                    (args["includeCertificate"] as Boolean)
                )

                "examineFile" -> examineFile(
                    (args["slot"] as String),
                    (args["data"] as String),
                    (args["password"] as String?)
                )

                "validateRfc4514" -> validateRfc4514(
                    (args["data"] as String)
                )

                "generate" -> generate(
                    Slot.fromStringAlias(args["slot"] as String),
                    (args["keyType"] as Int),
                    PinPolicy.fromValue(args["pinPolicy"] as Int),
                    TouchPolicy.fromValue(args["touchPolicy"] as Int),
                    (args["subject"] as String?),
                    (args["generateType"] as String),
                    (args["validFrom"] as String?),
                    (args["validTo"] as String?)
                )

                "importFile" -> importFile(
                    Slot.fromStringAlias(args["slot"] as String),
                    (args["data"] as String),
                    (args["password"] as String?),
                    PinPolicy.fromValue(args["pinPolicy"] as Int),
                    TouchPolicy.fromValue(args["touchPolicy"] as Int)
                )

                "getSlot" -> getSlot(
                    Slot.fromStringAlias(args["slot"] as String)
                )

                else -> throw NotImplementedError()
            }
        }
    }

    override fun supports(appContext: OperationContext): Boolean = when (appContext) {
        OperationContext.Piv -> true
        else -> false
    }

    private fun getPivSession(connection: SmartCardConnection): YubiKitPivSession {
        // If PIV is FIPS capable, and we have scpKeyParams, we should use them
        val fips = (deviceManager.deviceInfo?.fipsCapable ?: 0) and Capability.PIV.bit != 0
        val session = YubiKitPivSession(connection, if (fips) deviceManager.scpKeyParams else null)

        return session
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

    override fun hasPending(): Boolean = connectionHelper.hasPending()

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
        val smartCardConnection = connection as SmartCardConnection
        val piv = getPivSession(connection)

        val previousSerial = pivViewModel.currentSerial
        val currentSerial = if (piv.supports(FEATURE_SERIAL)) {
            piv.serialNumber
        } else {
            null
        }
        pivViewModel.setSerial(currentSerial)
        logger.debug(
            "Previous serial: {}, current serial: {}",
            previousSerial.value,
            currentSerial
        )

        val sameDevice = previousSerial.value == currentSerial

        if (!sameDevice || !connectionHelper.hasPending()) {
            connectionHelper.cancelPending()

            val (state, slots) = try {
                val piv = getPivSession(connection)
                readPivState(piv) to getSlots(piv)
            } catch (e: Exception) {
                logger.error("Error reading piv session. ", e)
                null to null
            }

            if (state == null) {
                pivViewModel.clearState()
            } else {
                pivViewModel.setState(state)
                pivViewModel.updateSlots(slots)
            }
        } else if (device is NfcYubiKeyDevice && connectionHelper.hasPending()) {
            requestHandled = connectionHelper.invokePending(smartCardConnection)
        }
        return requestHandled
    }

    private var pivmanData: PivmanData? = null

    private fun readPivState(connection: SmartCardConnection): PivState =
        readPivState(getPivSession(connection))

    private fun readPivState(piv: YubiKitPivSession): PivState {
        pivmanData = PivmanUtils.getPivmanData(piv)

        val supportsBio = try {
            piv.bioMetadata
            true
        } catch (e: Exception) {
            when (e) {
                is IOException, is ApduException, is UnsupportedOperationException -> false
                else -> throw e
            }
        }

        val usbCapabilities = deviceManager.deviceInfo?.config?.enabledCapabilities?.usb ?: 0
        val supportsFido = (usbCapabilities and Capability.FIDO2.bit) != 0
        val (pivStateMetadata, pinAttempts) =
            if (piv.supports(FEATURE_METADATA)) {
                val managementKeyMetadata = ManagementKeyMetadata(piv.managementKeyMetadata)
                val pinMetadata = PinMetadata(piv.pinMetadata)
                val pukMetadata = PinMetadata(piv.pukMetadata)

                PivStateMetadata(
                    managementKeyMetadata,
                    if (supportsBio and !supportsFido and piv.version.isLessThan(5, 8, 0)) {
                        // The default PIN flag may be set incorrectly on BIO MPE when FIDO2 is disabled
                        pinMetadata.copy(defaultValue = false)
                    } else {
                        pinMetadata
                    },
                    pukMetadata
                ) to pinMetadata.attemptsRemaining
            } else {
                null to piv.pinAttempts
            }

        return PivState(
            piv,
            authenticated = false,
            derivedKey = pivmanData?.hasDerivedKey ?: false,
            storedKey = pivmanData?.hasStoredKey ?: false,
            pinAttempts = pinAttempts,
            supportsBio = supportsBio,
            chuid = getObject(piv, ObjectId.CHUID)?.toHexString(),
            ccc = getObject(piv, ObjectId.CAPABILITY)?.toHexString(),
            metadata = pivStateMetadata
        )
    }

    private fun updatePivState(connection: SmartCardConnection) {
        pivViewModel.setState(readPivState(connection))
    }

    private fun getObject(piv: YubiKitPivSession, id: Int): ByteArray? =
        runCatching { piv.getObject(id) }.getOrElse { e ->
            if (e is ApduException && e.sw == SW.FILE_NOT_FOUND) null else throw e
        }

    private suspend fun reset(): String = connectionHelper.useSmartCardConnection(
        onComplete = ::updatePivState,
        updateDeviceInfo = true
    ) {
        val piv = getPivSession(it)
        piv.reset()
        ""
    }

    companion object {
        val defaultPin = "123456".toCharArray()
        val defaultManagementKey =
            "010203040506070801020304050607080102030405060708".hexToByteArray()
        val updateDeviceInfo = AtomicBoolean(false)
    }

    private fun doAuthenticate(piv: PivSession, serial: String) = try {
        var authenticated = false

        val hasProtectedKey = pivmanData?.hasProtectedKey ?: false

        if (hasProtectedKey) {
            // cannot use key from managementKeyStorage
            // has to use PIN to get the key from the session

            val pin = pinStorage[serial] ?: defaultPin
            piv.verifyPin(pin)

            val key = if (pivmanData?.hasDerivedKey ?: false) {
                PivmanUtils.deriveManagementKey(pin, pivmanData?.salt!!)
            } else if (pivmanData?.hasStoredKey ?: false) {
                val pivmanProtectedData = PivmanUtils.getPivmanProtectedData(piv)
                pivmanProtectedData.key
            } else {
                null
            }

            key?.let { key ->
                try {
                    piv.authenticate(key)
                    authenticated = true
                } catch (e: Exception) {
                    if (e is ApduException && e.sw == SW.SECURITY_CONDITION_NOT_SATISFIED) {
                        // pass
                    } else {
                        throw e
                    }
                }
                piv.verifyPin(pin)
            }
        } else {
            // the key is not protected
            authenticateKeyBySerial(piv, serial)
        }
        authenticated
    } catch (e: Exception) {
        pinStorage.remove(serial)
        throw e
    }

    private fun authenticateKeyBySerial(piv: PivSession, serial: String) = try {
        val managementKey = managementKeyStorage[serial] ?: defaultManagementKey
        piv.authenticate(managementKey)
    } catch (e: Exception) {
        managementKeyStorage.remove(serial)
        throw e
    }

    private suspend fun authenticate(managementKey: ByteArray): String =
        connectionHelper.useSmartCardConnection(
            onComplete = ::updatePivState,
            waitForNfcKeyRemoval = true
        ) {
            val serial = pivViewModel.currentSerial()
            try {
                managementKeyStorage[serial] = managementKey
                val piv = getPivSession(it)
                authenticateKeyBySerial(piv, serial)
                JSONObject(mapOf("status" to true)).toString()
            } catch (_: Exception) {
                JSONObject(mapOf("status" to false)).toString()
            }
        }

    private fun doVerifyPin(piv: PivSession, serial: String): String = try {
        var authenticated = false
        pinStorage[serial]?.let { pin ->
            piv.verifyPin(pin)

            val key = if (pivmanData?.hasDerivedKey ?: false) {
                PivmanUtils.deriveManagementKey(pin, pivmanData?.salt!!)
            } else if (pivmanData?.hasStoredKey ?: false) {
                val pivmanProtectedData = PivmanUtils.getPivmanProtectedData(piv)
                pivmanProtectedData.key
            } else {
                null
            }

            key?.let { key ->
                try {
                    piv.authenticate(key)
                    authenticated = true
                } catch (e: Exception) {
                    if (e is ApduException && e.sw == SW.SECURITY_CONDITION_NOT_SATISFIED) {
                        // pass
                    } else {
                        throw e
                    }
                }
                piv.verifyPin(pin)
            }
        }
        JSONObject(mapOf("status" to true, "authenticated" to authenticated)).toString()
    } catch (e: Exception) {
        pinStorage.remove(serial)
        throw e
    }

    private suspend fun verifyPin(pin: CharArray): String = connectionHelper.useSmartCardConnection(
        onComplete = ::updatePivState,
        waitForNfcKeyRemoval = true
    ) {
        try {
            val piv = getPivSession(it)
            val serial = pivViewModel.currentSerial()
            pinStorage[serial] = pin.clone()
            handlePinPukErrors { doVerifyPin(piv, serial) }
        } finally {
            Arrays.fill(pin, 0.toChar())
        }
    }

    private suspend fun changePin(pin: CharArray, newPin: CharArray): String =
        connectionHelper.useSmartCardConnection(
            onComplete = ::updatePivState,
            updateDeviceInfo = true
        ) {
            try {
                val piv = getPivSession(it)
                handlePinPukErrors { PivmanUtils.pivmanChangePin(piv, pin, newPin) }
            } finally {
                Arrays.fill(newPin, 0.toChar())
                Arrays.fill(pin, 0.toChar())
            }
        }

    private suspend fun changePuk(puk: CharArray, newPuk: CharArray): String =
        connectionHelper.useSmartCardConnection(
            onComplete = ::updatePivState,
            updateDeviceInfo = true
        ) {
            try {
                val piv = getPivSession(it)
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
    ): String = connectionHelper.useSmartCardConnection(
        onComplete = ::updatePivState,
        updateDeviceInfo = true
    ) {
        val piv = getPivSession(it)
        doVerifyPin(piv, pivViewModel.currentSerial())
        doAuthenticate(piv, pivViewModel.currentSerial())
        PivmanUtils.pivmanSetMgmKey(
            piv,
            newKey = managementKey,
            algorithm = keyType,
            touch = false,
            storeOnDevice = storeKey
        )
        ""
    }

    private suspend fun unblockPin(puk: CharArray, newPin: CharArray): String =
        connectionHelper.useSmartCardConnection(::updatePivState) {
            try {
                val piv = getPivSession(it)
                handlePinPukErrors { piv.unblockPin(puk, newPin) }
            } finally {
                Arrays.fill(newPin, 0.toChar())
                Arrays.fill(puk, 0.toChar())
            }
        }

    private fun handlePinPukErrors(block: () -> Unit): String {
        try {
            block()
            return JSONObject(mapOf("status" to "success")).toString()
        } catch (invalidPin: InvalidPinException) {
            return JSONObject(
                mapOf(
                    "status" to "invalid-pin",
                    "attemptsRemaining" to invalidPin.attemptsRemaining
                )
            ).toString()
        } catch (apduException: ApduException) {
            if (apduException.sw == SW.CONDITIONS_NOT_SATISFIED) {
                return JSONObject(mapOf("status" to "pin-complexity")).toString()
            }
        }
        return JSONObject(mapOf("status" to "other-error")).toString()
    }

    private fun getSlots(piv: YubiKitPivSession): List<PivSlot> =
        Slot.entries.minus(Slot.ATTESTATION).map {
            getSlot(it, piv)
        }

    private fun getSlot(slot: Slot, piv: YubiKitPivSession): PivSlot {
        val supportsMetadata = piv.supports(FEATURE_METADATA)
        val metadata = if (supportsMetadata) {
            runPivOperation { piv.getSlotMetadata(slot) }
        } else {
            null
        }
        val certificate = runPivOperation { piv.getCertificate(slot) }

        return PivSlot(
            slotId = slot.value,
            metadata = metadata?.let(::SlotMetadata),
            certificate = certificate,
            publicKeyMatch = null
        )
    }

    private suspend fun delete(slot: Slot, deleteCert: Boolean, deleteKey: Boolean): String =
        connectionHelper.useSmartCardConnection({
            pivViewModel.deleteSlot(slot, deleteCert, deleteKey)
        }) {
            val piv = getPivSession(it)
            val serial = pivViewModel.currentSerial()
            doVerifyPin(piv, serial)
            doAuthenticate(piv, serial)

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
        }

    private suspend fun moveKey(
        src: Slot,
        dst: Slot,
        overwriteKey: Boolean,
        includeCertificate: Boolean
    ): String = connectionHelper.useSmartCardConnection({ connection ->
        val piv = getPivSession(connection)
        pivViewModel.updateSlot(getSlot(src, piv))
        pivViewModel.updateSlot(getSlot(dst, piv))
    }) { connection ->
        val piv = getPivSession(connection)
        val serial = pivViewModel.currentSerial()

        doVerifyPin(piv, serial)
        doAuthenticate(piv, serial)

        val sourceObject = if (includeCertificate) {
            piv.getObject(src.objectId)
        } else {
            null
        }

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
    }

    private fun generateChuid(): ByteArray {
        // Non-Federal Issuer FASC-N
        // [9999-9999-999999-0-1-0000000000300001]
        val fascN = "D4E739DA739CED39CE739D836858210842108421C84210C3EB".hexToByteArray()

        // Expires on: 2030-01-01 -> "20300101" ASCII
        val expiry = "20300101".toByteArray(StandardCharsets.US_ASCII)

        // Random 16-byte GUID
        val guid = ByteArray(16).also { SecureRandom().nextBytes(it) }

        return Tlvs.encodeList(
            listOf(
                Tlv(0x30, fascN),
                Tlv(0x34, guid),
                Tlv(0x35, expiry),
                Tlv(0x3E, ByteArray(0)),
                Tlv(0xFE, ByteArray(0))
            )
        )
    }

    private fun chooseCertificate(certificates: List<X509Certificate>?): X509Certificate? =
        certificates?.let {
            when {
                it.size > 1 -> getLeafCertificates(it).firstOrNull()
                else -> it.firstOrNull()
            }
        }

    private fun getCertificateInfo(certificate: X509Certificate?) = certificate?.let {
        JSONObject(
            mapOf(
                "key_type" to (KeyType.fromKey(certificate.publicKey).value.toInt() and 0xff),
                "subject" to certificate.subjectDN.name,
                "issuer" to certificate.issuerDN.name,
                "serial" to certificate.serialNumber.toString(),
                "not_valid_before" to certificate.notBefore.isoFormat(),
                "not_valid_after" to certificate.notAfter.isoFormat(),
                "fingerprint" to certificate.fingerprint()
            )
        )
    }

    private fun publicKeyMatch(certificate: X509Certificate?, metadata: SlotMetadata?): Boolean? {
        if (certificate == null || metadata == null) {
            return null
        }

        val slotPublicKey = metadata.publicKey
        val certPublicKey = PublicKeyValues.fromPublicKey(certificate.publicKey)

        return slotPublicKey?.encoded.contentEquals(certPublicKey.encoded)
    }

    private fun examineFile(slot: String, data: String, password: String?): String = try {
        val (certificates, privateKey) = parseFile(data, password)
        val certificate = chooseCertificate(certificates)

        JSONObject(
            mapOf(
                "status" to true,
                "password" to (password != null),
                "key_type" to privateKey?.let {
                    KeyType.fromKeyParams(
                        PrivateKeyValues.fromPrivateKey(it)
                    ).value.toUByte().toInt() // JSONObject does not know UByte
                },
                "cert_info" to getCertificateInfo(certificate)
            )
        ).apply {
            pivViewModel.getMetadata(slot)?.let {
                if (certificate != null && privateKey == null) {
                    put("public_key_match", publicKeyMatch(certificate, it))
                }
            }
        }.toString()
    } catch (_: InvalidPasswordException) {
        JSONObject(mapOf("status" to false)).toString()
    }

    private fun getX500Name(data: String) = X500Name(data)

    private fun validateRfc4514(data: String): String = try {
        getX500Name(data)
        JSONObject(mapOf("status" to true)).toString()
    } catch (_: IllegalArgumentException) {
        JSONObject(mapOf("status" to false)).toString()
    }

    private suspend fun generate(
        slot: Slot,
        keyType: Int,
        pinPolicy: PinPolicy,
        touchPolicy: TouchPolicy,
        subject: String?,
        generateType: String,
        validFrom: String?,
        validTo: String?
    ): String = connectionHelper.useSmartCardConnection({ connection ->
        val piv = getPivSession(connection)
        pivViewModel.updateSlot(getSlot(slot, piv))
    }, true) {
        try {
            val piv = getPivSession(it)

            // Bug in yubikit-android KeyType.fromValue
            val keyTypeValue =
                KeyType.entries.first { entry -> entry.value.toUByte().toInt() == keyType }

            val serial = pivViewModel.currentSerial()
            doAuthenticate(piv, serial)

            val keyValues = piv.generateKeyValues(
                slot,
                keyTypeValue,
                pinPolicy,
                touchPolicy
            )

            if (pinPolicy != PinPolicy.NEVER) {
                doVerifyPin(piv, serial)
            }

            val publicKey = keyValues.toPublicKey()
            val publicKeyPem = publicKey.toPem()

            val result = when (generateType) {
                "publicKey" -> publicKeyPem
                "csr" -> {
                    if (subject == null) {
                        throw IllegalArgumentException("Subject missing for csr")
                    }
                    generateCsr(piv, slot, publicKey, subject).toPem()
                }

                "certificate" -> {
                    if (subject == null) {
                        throw IllegalArgumentException("Subject missing for csr")
                    }

                    val format = SimpleDateFormat("yyyy-MM-dd", Locale.US)
                    format.timeZone = TimeZone.getTimeZone("UTC")
                    val validFromDate = format.parse(validFrom!!)!!
                    val validToDate = format.parse(validTo!!)!!
                    val cert = generateSelfSignedCertificate(
                        piv,
                        slot,
                        publicKey,
                        subject,
                        validFromDate,
                        validToDate
                    )
                    val result = cert.toPem()
                    piv.putCertificate(slot, cert)
                    piv.putObject(ObjectId.CHUID, generateChuid())
                    result
                }

                else -> throw IllegalArgumentException("Invalid generate type: $generateType")
            }

            JSONObject(
                mapOf(
                    "public_key" to publicKeyPem,
                    "result" to result
                )
            ).toString()
        } catch (e: Exception) {
            throw e
        }
    }

    private fun parseFile(data: String, password: String?): KeyMaterial = try {
        parse(data.hexToByteArray(), password?.toCharArray())
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
        pinPolicy: PinPolicy,
        touchPolicy: TouchPolicy
    ): String = connectionHelper.useSmartCardConnection({ connection ->
        val piv = getPivSession(connection)
        pivViewModel.updateSlot(getSlot(slot, piv))
    }) {
        try {
            val piv = getPivSession(it)
            val serial = pivViewModel.currentSerial()

            doVerifyPin(piv, serial)
            doAuthenticate(piv, serial)

            val (certificates, privateKey) = parseFile(data, password)
            if (privateKey == null && certificates.isEmpty()) {
                throw IllegalArgumentException("Failed to parse")
            }

            var metadata: SlotMetadata? = null
            privateKey?.let {
                piv.putKey(
                    slot,
                    PrivateKeyValues.fromPrivateKey(privateKey),
                    pinPolicy,
                    touchPolicy
                )

                metadata = try {
                    SlotMetadata(piv.getSlotMetadata(slot))
                } catch (e: Exception) {
                    when (e) {
                        is ApduException,
                        is BadResponseException,
                        is UnsupportedOperationException -> null
                        else -> throw e
                    }
                }
            }

            val certificate = chooseCertificate(certificates)
            certificate?.let {
                piv.putCertificate(slot, certificate)
                piv.putObject(ObjectId.CHUID, generateChuid())
            }
            pivViewModel.updateSlot(slot.stringAlias, metadata, certificate)

            JSONObject(
                mapOf(
                    "metadata" to metadata?.let { slotMetadata ->
                        JSONObject(
                            mapOf(
                                "key_type" to slotMetadata.keyType.toInt(),
                                "pin_policy" to slotMetadata.pinPolicy,
                                "touch_policy" to slotMetadata.touchPolicy,
                                "generated" to slotMetadata.generated,
                                "public_key" to slotMetadata.publicKey?.toPublicKey()?.toPem()
                            )
                        )
                    },
                    "public_key" to privateKey?.let {
                        metadata?.publicKey?.toPublicKey()?.toPem()
                    },
                    "certificate" to
                        certificate?.encoded?.toHexString()
                )
            ).toString()
        } catch (e: Exception) {
            logger.error("Caught ", e)
            throw e
        }
    }

    private suspend fun getSlot(slot: Slot): String =
        connectionHelper.useSmartCardConnection(waitForNfcKeyRemoval = true) { piv ->
            JSONObject(
                mapOf(
                    "id" to slot.value,
                    "name" to slot.stringAlias,
                    "metadata" to pivViewModel.getMetadata(slot.stringAlias)?.let { slotMetadata ->
                        JSONObject(
                            mapOf(
                                "key_type" to slotMetadata.keyType.toInt(),
                                "pin_policy" to slotMetadata.pinPolicy,
                                "touch_policy" to slotMetadata.touchPolicy,
                                "generated" to slotMetadata.generated,
                                "public_key" to slotMetadata.publicKey?.toPublicKey()?.toPem()
                            )
                        )
                    },
                    "certificate" to pivViewModel.getCertificate(slot.stringAlias)?.toPem()
                )
            ).toString()
        }

    override fun onDisconnected() {
        pinStorage.clear()
        managementKeyStorage.clear()
        pivViewModel.setSerial(null)
        pivViewModel.updateSlots(emptyList())
        pivmanData = null
    }

    override fun onTimeout() {
        pivViewModel.clearState()
    }

    /**
     * Executes a PIV operation and returns null if it fails with a known,
     * recoverable exception. Other exceptions are re-thrown.
     */
    private fun <T> runPivOperation(operation: () -> T): T? = try {
        operation()
    } catch (e: Exception) {
        when (e) {
            is ApduException, is BadResponseException -> null
            else -> throw e
        }
    }
}
