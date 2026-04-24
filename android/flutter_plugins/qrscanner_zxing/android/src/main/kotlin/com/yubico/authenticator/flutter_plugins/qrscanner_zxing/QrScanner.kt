/*
 * Copyright (C) 2022-2026 Yubico.
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
package com.yubico.authenticator.flutter_plugins.qrscanner_zxing

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import com.google.zxing.BarcodeFormat
import com.google.zxing.BinaryBitmap
import com.google.zxing.DecodeHintType
import com.google.zxing.MultiFormatReader
import com.google.zxing.NotFoundException
import com.google.zxing.RGBLuminanceSource
import com.google.zxing.common.HybridBinarizer

object QrCodeScanner {

    private val qrCodeScanner = MultiFormatReader().also {
        it.setHints(
            mapOf(
                DecodeHintType.POSSIBLE_FORMATS to listOf(BarcodeFormat.QR_CODE),
                DecodeHintType.ALSO_INVERTED to true,
                DecodeHintType.TRY_HARDER to true
            )
        )
    }

    fun decodeFromBinaryBitmap(binaryBitmap: BinaryBitmap): String {
        val result = qrCodeScanner.decodeWithState(binaryBitmap)
        return result.text
    }

    private fun decodeFromBytes(
        byteArray: ByteArray,
        sampleSize: Int
    ): String? {
        var bitmap: Bitmap? = null
        try {
            Log.v(
                TAG,
                "Decoding with sampleSize $sampleSize"
            )
            val options = BitmapFactory.Options()
            options.inSampleSize = sampleSize
            bitmap = BitmapFactory.decodeByteArray(byteArray, 0, byteArray.size, options)
            bitmap?.let {
                val pixels = IntArray(it.allocationByteCount)
                it.getPixels(pixels, 0, it.width, 0, 0, it.width, it.height)

                val luminanceSource =
                    RGBLuminanceSource(it.width, it.height, pixels)

                val binaryBitmap = BinaryBitmap(HybridBinarizer(luminanceSource))
                val scanResult = decodeFromBinaryBitmap(binaryBitmap)
                Log.v(TAG, "Scan result: $scanResult")
                return scanResult
            }
            Log.e(TAG, "Could not decode image data.")
            return null
        } catch (_: NotFoundException) {
            Log.e(TAG, "No QR code found/decoded.")
            return null
        } catch (e: Throwable) {
            Log.e(TAG, "Exception while decoding data: ", e)
            return null
        } finally {
            bitmap?.recycle()
        }
    }

    fun decodeFromBytes(byteArray: ByteArray): String? {
        return decodeFromBytes(byteArray, 1)
            ?: decodeFromBytes(byteArray, 4)
            ?: decodeFromBytes(byteArray, 8)
            ?: decodeFromBytes(byteArray, 12)
    }

    private const val TAG = "QRScanner"
}