package com.yubico.authenticator.flutter_plugins.qrscanner_zxing

import com.google.zxing.BarcodeFormat
import com.google.zxing.BinaryBitmap
import com.google.zxing.DecodeHintType
import com.google.zxing.MultiFormatReader

object QrCodeScanner {

    private val qrCodeScanner = MultiFormatReader().also {
        it.setHints(mapOf(DecodeHintType.POSSIBLE_FORMATS to listOf(BarcodeFormat.QR_CODE)))
    }

    fun scan(binaryBitmap: BinaryBitmap) : String {
        val result: com.google.zxing.Result = qrCodeScanner.decode(binaryBitmap)
        return result.text
    }
}