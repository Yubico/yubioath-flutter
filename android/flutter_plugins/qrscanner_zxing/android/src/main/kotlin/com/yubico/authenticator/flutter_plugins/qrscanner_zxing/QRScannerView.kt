/*
 * Copyright (C) 2022 Yubico.
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

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.util.Size
import android.view.View
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.ContextCompat.startActivity
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import com.google.zxing.BinaryBitmap
import com.google.zxing.NotFoundException
import com.google.zxing.RGBLuminanceSource
import com.google.zxing.common.HybridBinarizer
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import org.json.JSONObject
import java.nio.ByteBuffer
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.Result
import kotlin.math.min

class QRScannerViewFactory(
    private val binaryMessenger: BinaryMessenger,
    private val permissionsResultRegistrar: PermissionsResultRegistrar
) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    @Suppress("UNCHECKED_CAST")
    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as Map<String?, Any?>?
        return QRScannerView(
            context!!,
            viewId,
            binaryMessenger,
            permissionsResultRegistrar,
            creationParams
        )
    }
}

typealias BarcodeAnalyzerListener = (Result<String>) -> Unit

internal class QRScannerView(
    context: Context,
    @Suppress("UNUSED_PARAMETER") id: Int,
    binaryMessenger: BinaryMessenger,
    private val permissionsResultRegistrar: PermissionsResultRegistrar,
    creationParams: Map<String?, Any?>?
) : PlatformView {

    private val stateChangeObserver = StateChangeObserver(context)
    private val uiThreadHandler = Handler(Looper.getMainLooper())

    companion object {
        const val TAG = "QRScannerView"

        // permission related
        const val PERMISSION_REQUEST_CODE = 1
        private val PERMISSIONS_TO_REQUEST =
            mutableListOf(
                Manifest.permission.CAMERA,
            ).toTypedArray()

        // communication channel
        private const val CHANNEL_NAME =
            "com.yubico.authenticator.flutter_plugins.qr_scanner_channel"
    }

    private fun allPermissionsGranted(activity: Activity) = PERMISSIONS_TO_REQUEST.all {
        ContextCompat.checkSelfPermission(
            activity, it
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestPermissions(activity: Activity) {
        ActivityCompat.requestPermissions(
            activity,
            PERMISSIONS_TO_REQUEST,
            PERMISSION_REQUEST_CODE
        )
    }

    private val qrScannerView = View.inflate(context, R.layout.qr_scanner_view, null)
    private val previewView = qrScannerView.findViewById<PreviewView>(R.id.preview_view).also {
        it.scaleType = PreviewView.ScaleType.FILL_CENTER
        it.implementationMode = PreviewView.ImplementationMode.PERFORMANCE
    }

    private val cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
    private var cameraProvider: ProcessCameraProvider? = null
    private val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

    private var imageAnalysis: ImageAnalysis? = null
    private var preview: Preview? = null
    private val barcodeAnalyzer = with(creationParams) {
        var marginPct : Double? = null
        if (this?.get("margin") is Number) {
            val marginValue = this["margin"] as Number
            if (marginValue.toDouble() > 0.0 && marginValue.toDouble() < 45) {
                marginPct = marginValue.toDouble()
            }
        }

        BarcodeAnalyzer(marginPct) { analyzeResult ->
            if (analyzeResult.isSuccess) {
                analyzeResult.getOrNull()?.let { result ->
                    reportCodeFound(result)
                }
            }
        }
    }

    override fun getView(): View {
        barcodeAnalyzer.analysisPaused = false
        return qrScannerView
    }


    override fun dispose() {
        cameraProvider?.unbindAll()
        preview = null
        imageAnalysis?.clearAnalyzer()
        imageAnalysis = null
        cameraExecutor.shutdown()
        methodChannel.setMethodCallHandler(null)
        Log.v(TAG, "dispose()")
    }

    private val methodChannel: MethodChannel = MethodChannel(binaryMessenger, CHANNEL_NAME)
    private var permissionsGranted = false

    private val screenSize = with(context.resources.displayMetrics) {
        Size(widthPixels, heightPixels)
    }

    init {
        if (context is Activity) {
            permissionsGranted = allPermissionsGranted(context)

            if (!permissionsGranted) {
                Log.v(TAG, "permissionsGranted = false -> requesting permission")
                requestPermissionsFromUser(context)
            } else {
                Log.v(TAG, "permissionsGranted = true -> binding use cases")
                bindUseCases(context)
            }

            methodChannel.setMethodCallHandler { call, _ ->
                if (call.method == "requestCameraPermissions") {
                    requestPermissionsFromUser(context)

                    val intent = Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.parse("package:" + context.getPackageName())
                    )
                    intent.addCategory(Intent.CATEGORY_DEFAULT)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(context, intent, null)
                } else if (call.method == "resumeScanning") {
                    barcodeAnalyzer.analysisPaused = false
                }
            }
        }
    }

    private fun requestPermissionsFromUser(activity: Activity) {
        permissionsResultRegistrar.setListener(
            object : PluginRegistry.RequestPermissionsResultListener {
                override fun onRequestPermissionsResult(
                    requestCode: Int,
                    permissions: Array<out String>,
                    grantResults: IntArray
                ): Boolean {
                    if (requestCode == PERMISSION_REQUEST_CODE) {
                        if (permissions.size == 1 && grantResults.size == 1) {
                            if (permissions.first() == PERMISSIONS_TO_REQUEST.first() &&
                                grantResults.first() == PackageManager.PERMISSION_GRANTED
                            ) {
                                previewView.visibility = View.VISIBLE
                                bindUseCases(activity)
                            } else {
                                previewView.visibility = View.GONE
                                reportViewInitialized(false)
                            }
                        } else {
                            previewView.visibility = View.GONE
                            reportViewInitialized(false)
                        }
                        return true
                    }

                    return false
                }
            })

        requestPermissions(activity)
    }

    private fun reportViewInitialized(permissionsGranted: Boolean) {
        uiThreadHandler.post {
            methodChannel.invokeMethod(
                "viewInitialized",
                JSONObject(mapOf("permissionsGranted" to permissionsGranted)).toString()
            )
        }
    }

    private fun reportCodeFound(code: String) {
        uiThreadHandler.post {
            methodChannel.invokeMethod(
                "codeFound", JSONObject(
                    mapOf("value" to code)
                ).toString()
            )
        }
    }

    private fun bindUseCases(context: Context) {
        cameraProviderFuture.addListener({

            previewView.visibility = View.VISIBLE
            cameraProvider = cameraProviderFuture.get()

            cameraProvider?.unbindAll()

            imageAnalysis = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .setTargetResolution(Size(768,1024))
                .build()
                .also {
                    it.setAnalyzer(cameraExecutor, barcodeAnalyzer)
                }

            preview = Preview.Builder()
                .setTargetResolution(screenSize)
                .build()
                .also {
                    it.setSurfaceProvider(previewView.surfaceProvider)
                }

            val camera = cameraProvider?.bindToLifecycle(
                context as LifecycleOwner,
                cameraSelector,
                preview, imageAnalysis
            )

            camera?.cameraInfo?.cameraState?.let {
                it.removeObservers(context as LifecycleOwner)
                it.observe(context as LifecycleOwner, stateChangeObserver)
            }

            reportViewInitialized(true)
        }, ContextCompat.getMainExecutor(context))
    }

    private class BarcodeAnalyzer(
        private val marginPct: Double?, private val listener: BarcodeAnalyzerListener
    ) : ImageAnalysis.Analyzer {

        var analysisPaused = false
        var analyzedImagesCount = 0

        private fun ByteBuffer.toByteArray(lastRowPadding: Int): ByteArray {
            rewind()
            val size = remaining()
            val paddedSize = size + lastRowPadding
            val data = ByteArray(paddedSize)
            get(data, 0, size)
            data.fill(0, size, paddedSize)
            return data
        }

        override fun analyze(imageProxy: ImageProxy) {
            try {

                if (analysisPaused) {
                    return
                }

                val plane0 = imageProxy.planes[0]

                if (analyzedImagesCount == 0) {
                    Log.v(TAG, "First image received for analysis:")
                    Log.v(TAG, "  Image format: ${imageProxy.format}")
                    Log.v(TAG, "  WxH: ${imageProxy.width}x${imageProxy.height}")

                    for (indexedPlane in imageProxy.planes.withIndex()) {
                        val index = indexedPlane.index
                        val plane = indexedPlane.value

                        try {
                            Log.v(TAG, "  plane[$index].rowStride: ${plane.rowStride} ")
                        } catch (_: UnsupportedOperationException) {
                            Log.v(TAG, "  plane[$index].rowStride: Unsupported Operation")
                        }
                        try {
                            Log.v(TAG, "  plane[$index].pixelStride: ${plane.pixelStride}")
                        } catch (_: UnsupportedOperationException) {
                            Log.v(TAG, "  plane[$index].pixelStride: Unsupported Operation")
                        }

                        Log.v(TAG, "  plane[$index].buffer.size: ${plane.buffer.toByteArray(0).size}")
                    }
                }

                val buffer = plane0.buffer
                val rowStride = plane0.rowStride

                // the new array has to pad extra size for situation when rowStride > image width
                val intArray =
                    buffer.toByteArray(rowStride - imageProxy.width).map { it.toInt() }.toIntArray()

                val planeLuminanceSource =
                    RGBLuminanceSource(rowStride, imageProxy.height, intArray)

                val luminanceSource =
                    if (rowStride > imageProxy.width && planeLuminanceSource.isCropSupported) {
                        if (analyzedImagesCount == 0) {
                            Log.v(
                                TAG, "  row stride greater than image -> "+
                                        "cropping luminance source of size " +
                                        "${plane0.rowStride}x${imageProxy.height} to " +
                                        "${imageProxy.width}x${imageProxy.height}"
                            )
                        }
                        planeLuminanceSource.crop(0, 0, imageProxy.width, imageProxy.height)
                    } else {
                        planeLuminanceSource
                    }

                val fullSize = BinaryBitmap(HybridBinarizer(luminanceSource))

                val bitmapToProcess = if (marginPct != null && fullSize.isCropSupported) {
                    val shorterDim = min(imageProxy.width, imageProxy.height)
                    val cropMargin = marginPct * 0.01 * shorterDim
                    val cropWH = shorterDim - 2.0 * cropMargin
                    val cropT = (imageProxy.height - cropWH) / 2.0
                    val cropL = (imageProxy.width - cropWH) / 2.0
                    if(analyzedImagesCount == 0) {
                        Log.v(TAG, "  bitmap l:t:w:h $cropL:$cropT:$cropWH:$cropWH")
                    }
                    fullSize.crop(
                        cropL.toInt(),
                        cropT.toInt(),
                        cropWH.toInt(),
                        cropWH.toInt()
                    )
                } else {
                    if(analyzedImagesCount == 0) {
                        Log.v(
                            TAG,
                            "  bitmap l:t:w:h 0:0:${imageProxy.width}:${imageProxy.height} (full size)"
                        )
                    }
                    fullSize
                }

                val result = QrCodeScanner.decodeFromBinaryBitmap(bitmapToProcess)
                if (analysisPaused) {
                    return
                }

                analysisPaused = true // pause
                Log.v(TAG, "Analysis result: $result")
                listener.invoke(Result.success(result))
            } catch (_: NotFoundException) {
                if (analyzedImagesCount == 0) {
                    Log.v(TAG, "  No QR code found (NotFoundException)")
                }
            } finally {
                // important call
                imageProxy.close()
                analyzedImagesCount++

                if (analyzedImagesCount % 50 == 0) {
                    Log.v(TAG, "Count of analyzed images so far: $analyzedImagesCount")
                }
            }
        }
    }

    private class StateChangeObserver(val context: Context) : Observer<CameraState> {
        private var cameraOpened: Boolean = false

        override fun onChanged(t: CameraState) {
            Log.v(TAG, "Camera state changed to ${t.type}")

            if (t.type == CameraState.Type.OPEN) {
                cameraOpened = true
            }

            if (cameraOpened && t.type == CameraState.Type.CLOSED) {
                Log.v(TAG, "Camera closed")
                val stateChangedIntent =
                    Intent("com.yubico.authenticator.QRScannerView.CameraClosed")
                context.sendBroadcast(stateChangedIntent)
                cameraOpened = false
            }
        }
    }

}
