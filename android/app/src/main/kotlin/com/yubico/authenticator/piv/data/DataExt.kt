@file:OptIn(ExperimentalStdlibApi::class)

package com.yubico.authenticator.piv.data

import android.os.Build
import java.security.MessageDigest
import java.security.cert.X509Certificate
import java.text.SimpleDateFormat
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Date
import java.util.Locale
import java.util.TimeZone

fun ByteArray.byteArrayToHexString(): String = toHexString()

fun String.hexStringToByteArray(): ByteArray = hexToByteArray()

fun Date.isoFormat(): String = if (Build.VERSION.SDK_INT >= 26) {
    toInstant().atZone(ZoneId.systemDefault()).format(DateTimeFormatter.ISO_OFFSET_DATE_TIME)
} else {
    @Suppress("SpellCheckingInspection")
    val isoFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
    val sdf = SimpleDateFormat(isoFormat, Locale.US)
    sdf.timeZone = TimeZone.getTimeZone("UTC")
    sdf.format(this)
}

fun X509Certificate.fingerprint(): String =
    MessageDigest.getInstance("SHA-256").digest(encoded).byteArrayToHexString()