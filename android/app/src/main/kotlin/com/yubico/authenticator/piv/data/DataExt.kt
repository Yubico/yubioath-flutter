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

@OptIn(ExperimentalStdlibApi::class)
fun ByteArray.byteArrayToHexString(): String = toHexString()

@OptIn(ExperimentalStdlibApi::class)
fun String.hexStringToByteArray(): ByteArray = hexToByteArray()

fun Date.isoFormat(): String = if (Build.VERSION.SDK_INT >= 26) {
    toInstant().atZone(ZoneId.systemDefault()).format(DateTimeFormatter.ISO_LOCAL_DATE)
} else {
    val isoFormat = "yyyy-MM-dd"
    val sdf = SimpleDateFormat(isoFormat, Locale.US)
    sdf.timeZone = TimeZone.getTimeZone("UTC")
    sdf.format(this)
}

fun X509Certificate.fingerprint(): String =
    MessageDigest
        .getInstance("SHA-256")
        .digest(encoded)
        .byteArrayToHexString()