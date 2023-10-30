package com.yubico.authenticator.flutter_plugins.qrscanner_zxing

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint
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
        sampleSize: Int,
        rotation: Int,
        boostContrast: Boolean
    ): String? {
        var bitmap: Bitmap? = null
        try {
            Log.v(
                TAG,
                "Decoding with sampleSize $sampleSize, rotation $rotation, boostContrast: $boostContrast"
            )
            bitmap = getScaledBitmap(byteArray, sampleSize, boostContrast)
            bitmap?.let {
                val pixels = IntArray(it.allocationByteCount)
                it.getPixels(pixels, 0, it.width, 0, 0, it.width, it.height)

                val luminanceSource =
                    RGBLuminanceSource(it.width, it.height, pixels)

                var binaryBitmap = BinaryBitmap(HybridBinarizer(luminanceSource))

                if (rotation in 1..3 && binaryBitmap.isRotateSupported) {
                    for (r in 1..rotation) {
                        binaryBitmap = binaryBitmap.rotateCounterClockwise()
                    }
                }

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
            bitmap?.let {
                it.recycle()
                bitmap = null
            }
        }
    }

    fun decodeFromBytes(byteArray: ByteArray): String? {
        for (boostContrast in sequenceOf(false, true)) {
            for (rotation in 0 until 4) {
                for (sampleSize in sequenceOf(1, 4, 8, 12)) {
                    val code = decodeFromBytes(byteArray, sampleSize, rotation, boostContrast)
                    if (code != null) {
                        return code
                    }
                }
            }
        }
        return null
    }

    private fun getScaledBitmap(
        byteArray: ByteArray,
        sampleSize: Int,
        boostContrast: Boolean
    ): Bitmap? {
        var inputBitmap: Bitmap? = null
        try {
            val options = BitmapFactory.Options()
            options.inSampleSize = sampleSize
            inputBitmap = BitmapFactory.decodeByteArray(byteArray, 0, byteArray.size, options)
            inputBitmap?.let {
                val drawingBitmap =
                    Bitmap.createBitmap(it.width, it.height, Bitmap.Config.ARGB_8888)

                val canvas = Canvas(drawingBitmap)
                val cm = ColorMatrix()
                if (boostContrast) {

                    val contrast = 0f
                    val scale = contrast + 1f
                    val translate = (-.5f * scale + .5f) * 255f

                    cm.setSaturation(0f)
                    cm.postConcat(
                        ColorMatrix(
                            floatArrayOf(
                                scale, 0f, 0f, 0f, translate,
                                0f, scale, 0f, 0f, translate,
                                0f, 0f, scale, 0f, translate,
                                0f, 0f, 0f, scale, 0f
                            )
                        )
                    )
                }

                val paint = Paint()
                paint.setColorFilter(ColorMatrixColorFilter(cm))
                canvas.drawBitmap(it, 0f, 0f, paint)

                return drawingBitmap
            }
        } finally {
            inputBitmap?.recycle()
        }

        return null
    }


    private const val TAG = "QRScanner"
}