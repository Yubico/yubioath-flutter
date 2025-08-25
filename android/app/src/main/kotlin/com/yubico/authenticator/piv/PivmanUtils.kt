package com.yubico.authenticator.piv

import com.yubico.authenticator.piv.data.PivmanData
import com.yubico.authenticator.piv.data.PivmanProtectedData
import com.yubico.yubikit.core.smartcard.ApduException
import com.yubico.yubikit.core.smartcard.SW
import com.yubico.yubikit.piv.ManagementKeyType
import com.yubico.yubikit.piv.ObjectId
import org.slf4j.LoggerFactory
import java.security.SecureRandom
import java.security.spec.KeySpec
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec

object PivmanUtils {
    private val logger = LoggerFactory.getLogger(PivmanUtils::class.java)

    /**
     * Reads and parses Pivman data from the given PIV session.
     * If no data exists on the device, returns a blank PivmanData instance.
     *
     * @param piv The YubiKitPivSession to read from.
     * @return The parsed [com.yubico.authenticator.piv.data.PivmanData] object.
     * @throws com.yubico.yubikit.core.smartcard.ApduException if an error occurs other than file not found.
     */
    internal fun getPivmanData(piv: YubiKitPivSession): PivmanData {
        logger.trace("Reading pivman data")
        try {
            return PivmanData(piv.getObject(ObjectId.PIVMAN_DATA))
        } catch (e: ApduException) {
            if (e.sw == SW.FILE_NOT_FOUND) {
                logger.trace("No pivman data, initializing blank")
                return PivmanData()
            }
            throw e
        }
    }

    /**
     * Reads and parses protected Pivman data from the given PIV session.
     * If no protected data exists, returns a blank PivmanProtectedData instance.
     *
     * @param piv The PivSession to read from.
     * @return The parsed [com.yubico.authenticator.piv.data.PivmanProtectedData] object.
     * @throws IllegalArgumentException if the protected data is invalid.
     * @throws ApduException if an error occurs other than file not found.
     */
    internal fun getPivmanProtectedData(piv: YubiKitPivSession): PivmanProtectedData {
        logger.trace("Reading protected pivman data")
        try {
            return PivmanProtectedData(piv.getObject(ObjectId.PIVMAN_PROTECTED_DATA))
        } catch (e: ApduException) {
            if (e.sw == SW.FILE_NOT_FOUND) {
                logger.trace("No pivman protected data, initializing blank")
                return PivmanProtectedData()
            }
            throw e
        } catch (_: Exception) {
            throw IllegalArgumentException(
                "Invalid data in protected slot (${
                    ObjectId.PIVMAN_PROTECTED_DATA.toString(16)
                })"
            )
        }
    }

    /**
     * Sets the management key on the PIV session and updates relevant Pivman data.
     * Optionally stores the management key in protected data on the device.
     *
     * @param piv The PivSession to operate on.
     * @param newKey The new management key as a [ByteArray].
     * @param algorithm The type of management key algorithm.
     * @param touch Whether touch is required to use the management key.
     * @param storeOnDevice If true, stores the key in protected data on the device.
     * @throws ApduException if an error occurs while writing to the device.
     */
    internal fun pivmanSetMgmKey(
        piv: YubiKitPivSession,
        newKey: ByteArray,
        algorithm: ManagementKeyType,
        touch: Boolean = false,
        storeOnDevice: Boolean = false,
    ) {
        val pivman = getPivmanData(piv)
        val pivmanOldBytes = pivman.getBytes()
        var pivmanProt: PivmanProtectedData? = null

        if (storeOnDevice || (!storeOnDevice && pivman.hasStoredKey)) {
            try {
                pivmanProt = getPivmanProtectedData(piv)
            } catch (e: Exception) {
                logger.trace("Failed to initialize protected pivman data: {}", e.message)
                if (storeOnDevice) throw e
            }
        }

        piv.setManagementKey(algorithm, newKey, touch)

        if (pivman.hasDerivedKey) {
            logger.trace("Clearing salt in pivman data")
            pivman.salt = null
        }

        pivman.mgmKeyProtected = storeOnDevice

        val pivmanBytes = pivman.getBytes()
        if (!pivmanOldBytes.contentEquals(pivmanBytes)) {
            piv.putObject(ObjectId.PIVMAN_DATA, pivmanBytes)
        }

        if (pivmanProt != null) {
            if (storeOnDevice) {
                logger.trace("Storing key in protected pivman data")
                pivmanProt.key = newKey
                piv.putObject(ObjectId.PIVMAN_PROTECTED_DATA, pivmanProt.getBytes())
            } else if (pivmanProt.key != null) {
                logger.trace("Clearing old key in protected pivman data")
                try {
                    pivmanProt.key = null
                    piv.putObject(ObjectId.PIVMAN_PROTECTED_DATA, pivmanProt.getBytes())
                } catch (e: ApduException) {
                    logger.trace("No PIN provided, can't clear key... ({})", e.message)
                }
            }
        }
    }

    /**
     * Changes the PIN on the YubiKey and, if applicable, updates the derived management key.
     *
     * @param piv The YubiKitPivSession to operate on.
     * @param oldPin The current PIN as a [CharArray].
     * @param newPin The new PIN as a [CharArray].
     * @throws ApduException if an error occurs during PIN change.
     */
    internal fun pivmanChangePin(piv: YubiKitPivSession, oldPin: CharArray, newPin: CharArray) {
        piv.changePin(oldPin, newPin)

        val pivmanData = getPivmanData(piv)
        if (pivmanData.hasDerivedKey) {
            logger.trace("Has derived management key, update for new PIN")
            piv.authenticate(deriveManagementKey(oldPin, pivmanData.salt!!))
            piv.verifyPin(newPin)
            val newSalt = SecureRandom().generateSeed(16)
            val newKey = deriveManagementKey(newPin, newSalt)
            piv.setManagementKey(ManagementKeyType.TDES, newKey, false)
            pivmanData.salt = newSalt
            piv.putObject(ObjectId.PIVMAN_DATA, pivmanData.getBytes())
        }
    }

    /**
     * Sets the maximum number of PIN and PUK attempts on the YubiKey and clears the blocked status if needed.
     *
     * @param piv The YubiKitPivSession to operate on.
     * @param pinAttempts The number of allowed PIN attempts.
     * @param pukAttempts The number of allowed PUK attempts.
     * @throws ApduException if an error occurs during the operation.
     */
    internal fun pivmanSetPinAttempts(piv: YubiKitPivSession, pinAttempts: Int, pukAttempts: Int) {
        piv.setPinAttempts(pinAttempts, pukAttempts)
        val pivman = getPivmanData(piv)
        if (pivman.pukBlocked) {
            pivman.pukBlocked = false
            piv.putObject(ObjectId.PIVMAN_DATA, pivman.getBytes())
        }
    }

    /**
     * Derives a management key from the user's PIN and a salt using PBKDF2.
     *
     * **Deprecated:** This method of derivation is deprecated! Protect the management key using [PivmanProtectedData] instead.
     *
     * @param pin The PIN as a [CharArray].
     * @param salt The salt as a [ByteArray].
     * @return The derived management key as a [ByteArray].
     */
    @Deprecated(
        "This method of derivation is deprecated! Protect the management key using PivmanProtectedData instead.",
        ReplaceWith("PivmanProtectedData")
    )
    internal fun deriveManagementKey(pin: CharArray, salt: ByteArray): ByteArray {
        val iterations = 10000
        val keyLength = 24 * 8 // 24 bytes = 192 bits (for TDES)
        val factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA1")
        val spec: KeySpec = PBEKeySpec(pin, salt, iterations, keyLength)
        val key = factory.generateSecret(spec).encoded
        return key
    }
}