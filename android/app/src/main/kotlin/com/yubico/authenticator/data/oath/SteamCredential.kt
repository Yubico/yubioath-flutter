package com.yubico.authenticator.data.oath

import com.yubico.yubikit.oath.Code
import com.yubico.yubikit.oath.Credential
import com.yubico.yubikit.oath.OathSession
import com.yubico.yubikit.oath.OathType
import java.nio.ByteBuffer
import kotlin.experimental.and

/**
 * Returns true if this credential is considered to be Steam credential
 */
fun Credential.isSteamCredential(): Boolean =
    issuer == "Steam" && oathType == OathType.TOTP

/**
 * @return Code with value formatted for use with Steam
 * @param credential credential that will get new Steam code
 * @param timestamp the timestamp which is used for TOTP calculation
 * @throws IllegalArgumentException in case when the credential is not a Steam credential
 */
fun OathSession.calculateSteamCode(
    credential: Credential,
    timestamp: Long = 0,
): Code {
    val timeSlotMs = 30_000
    if (!credential.isSteamCredential()) {
        throw IllegalArgumentException("This is not steam credential")
    }

    val currentTimeSlot = timestamp / timeSlotMs

    return Code(
        calculateResponse(credential.id, currentTimeSlot.toByteArray()).formatAsSteam(),
        currentTimeSlot * timeSlotMs,
        (currentTimeSlot + 1) * timeSlotMs
    )
}

private fun ByteArray.formatAsSteam(): String {
    val steamCharTable = "23456789BCDFGHJKMNPQRTVWXY"
    val charTableLen = steamCharTable.length
    val offset = (this[this.size - 1] and 0x0f).toInt()
    var number = ByteBuffer.wrap(this, offset, 4).int and 0x7fffffff
    return String(CharArray(5) {
        steamCharTable[number % charTableLen].also { number /= charTableLen }
    })
}

private fun Long.toByteArray() = ByteBuffer.allocate(8).putLong(this).array()


