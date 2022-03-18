package com.yubico.authenticator.data.oath

import com.yubico.yubikit.oath.Code
import com.yubico.yubikit.oath.Credential
import com.yubico.yubikit.oath.OathType
import java.nio.ByteBuffer
import kotlin.experimental.and

/**
 * Returns true if this credential is considered to be Steam credential
 */
fun Credential.isSteamCredential(): Boolean =
    issuer == "Steam" && oathType == OathType.TOTP

/**
 * @return Five character TOTP code for Steam
 * @param timestamp timestamp to compute the Steam code for
 * @param calculateResponse computes response for credential id and challenge based on the Steam
 *                          properties of the timestamp
 * @throws IllegalArgumentException in case when the credential is not a Steam credential
 */
fun Credential.calculateSteamCode(
    timestamp: Long,
    calculateResponse: (credentialId: ByteArray, challenge: ByteArray) -> ByteArray
): Code {
    val timeSlotMs = 30_000
    if (!isSteamCredential()) {
        throw IllegalArgumentException("This is not steam credential")
    }

    val currentTimeSlot = timestamp / timeSlotMs

    return Code(
        format(calculateResponse(id, currentTimeSlot.toByteArray())),
        currentTimeSlot * timeSlotMs,
        (currentTimeSlot + 1) * timeSlotMs
    )
}

private fun format(code: ByteArray): String {
    val steamCharTable = "23456789BCDFGHJKMNPQRTVWXY"
    val charTableLen = steamCharTable.length
    val offset = code[code.size - 1].and(0x0f).toInt()
    var number = ByteBuffer.wrap(code, offset, 4).int.and(0x7fffffff)
    return String(CharArray(5) {
        steamCharTable[number % charTableLen].also { number /= charTableLen }
    })
}

private fun Long.toByteArray() = ByteBuffer.allocate(8).putLong(this).array()


