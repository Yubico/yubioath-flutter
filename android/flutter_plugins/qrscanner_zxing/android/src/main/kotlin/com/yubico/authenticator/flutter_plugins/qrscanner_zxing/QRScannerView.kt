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

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.camera2.CaptureRequest
import android.provider.Settings
import android.util.Log
import android.util.Size
import android.view.OrientationEventListener
import android.view.Surface
import android.view.View
import android.view.ViewTreeObserver
import androidx.annotation.OptIn
import androidx.camera.camera2.interop.Camera2Interop
import androidx.camera.camera2.interop.ExperimentalCamera2Interop
import androidx.camera.core.CameraSelector
import androidx.camera.core.CameraState
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.ContextCompat.startActivity
import androidx.core.net.toUri
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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
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

@OptIn(ExperimentalCamera2Interop::class)
internal class QRScannerView
    (
    context: Context,
    @Suppress("UNUSED_PARAMETER") id: Int,
    binaryMessenger: BinaryMessenger,
    private val permissionsResultRegistrar: PermissionsResultRegistrar,
    creationParams: Map<String?, Any?>?
) : PlatformView {

    private val stateChangeObserver = StateChangeObserver(context)
    // SupervisorJob lets child coroutines (reportCodeFound, reportViewInitialized) fail
    // independently; cancelled in dispose() so no calls reach a detached methodChannel.
    private val coroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    // Prevents the async cameraProviderFuture listener from rebinding after dispose().
    @Volatile private var viewDisposed = false

    companion object {
        const val TAG = "QRScannerView"

        // permission related
        const val PERMISSION_REQUEST_CODE = 1
        private val PERMISSIONS_TO_REQUEST = arrayOf(Manifest.permission.CAMERA)

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
        methodChannel.invokeMethod(
            "beforePermissionsRequest", null
        )

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

    // Stable view dimensions — pre-seeded from creationParams so the very first frame has
    // non-zero values (avoids full-buffer scan before the layout listener fires).
    // Updated via OnGlobalLayoutListener whenever the layout settles.
    @Volatile private var stableViewWidth =
        (creationParams?.get("viewWidth") as? Number)?.toDouble() ?: 0.0
    @Volatile private var stableViewHeight =
        (creationParams?.get("viewHeight") as? Number)?.toDouble() ?: 0.0

    private val layoutListener = ViewTreeObserver.OnGlobalLayoutListener {
        // Guard against early layout passes where the view hasn't been measured yet.
        // Without this, a zero value clobbers the non-zero creationParams seed and causes
        // the analyzer to fall back to full-buffer scanning until the next layout event.
        val w = previewView.width.toDouble()
        val h = previewView.height.toDouble()
        if (w > 0 && h > 0) {
            stableViewWidth = w
            stableViewHeight = h
            barcodeAnalyzer.viewWidth = w
            barcodeAnalyzer.viewHeight = h
        }
    }

    // CameraX docs: PreviewView handles Preview use case rotation automatically.
    // Only ImageAnalysis needs manual targetRotation updates via OrientationEventListener.
    // No camera rebind is needed on rotation — just updating targetRotation is sufficient.
    // Mapping from the official CameraX rotation documentation:
    //   45–135° → ROTATION_270, 135–225° → ROTATION_180, 225–315° → ROTATION_90, else → ROTATION_0
    private val orientationEventListener = object : OrientationEventListener(context) {
        override fun onOrientationChanged(orientation: Int) {
            if (orientation == ORIENTATION_UNKNOWN) return
            val rotation = when (orientation) {
                in 45 until 135 -> Surface.ROTATION_270
                in 135 until 225 -> Surface.ROTATION_180
                in 225 until 315 -> Surface.ROTATION_90
                else -> Surface.ROTATION_0
            }
            imageAnalysis?.targetRotation = rotation
        }
    }

    private var imageAnalysis: ImageAnalysis? = null
    private var preview: Preview? = null
    private val barcodeAnalyzer = with(creationParams) {
        val overlaySizeFraction = (this?.get("overlaySizeFraction") as? Number)?.toDouble() ?: 0.65

        BarcodeAnalyzer(overlaySizeFraction) { analyzeResult ->
            if (analyzeResult.isSuccess) {
                analyzeResult.getOrNull()?.let { result ->
                    reportCodeFound(result)
                }
            }
        }.also {
            // Pre-seed with values from creationParams so the first frame has non-zero
            // dimensions (stableViewWidth/Height were already initialized from creationParams).
            it.viewWidth = stableViewWidth
            it.viewHeight = stableViewHeight
        }
    }

    override fun getView(): View {
        barcodeAnalyzer.analysisPaused = false
        return qrScannerView
    }

    override fun dispose() {
        viewDisposed = true
        permissionsResultRegistrar.setListener(null)
        orientationEventListener.disable()
        previewView.viewTreeObserver.removeOnGlobalLayoutListener(layoutListener)
        // Do NOT call stateChangeObserver.reset() here. When the QR scanner is dismissed,
        // the CLOSED event from unbindAll() is the intended trigger for the CameraClosed
        // broadcast that restarts NFC. reset() is only called inside bindUseCases() to
        // suppress the spurious CLOSED fired during a rebind, not on final teardown.
        cameraProvider?.unbindAll()
        preview = null
        imageAnalysis?.clearAnalyzer()
        imageAnalysis = null
        cameraExecutor.shutdown()
        methodChannel.setMethodCallHandler(null)
        coroutineScope.cancel()
        Log.v(TAG, "dispose()")
    }

    private val methodChannel: MethodChannel = MethodChannel(binaryMessenger, CHANNEL_NAME)
    private var permissionsGranted = false

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
                        "package:${context.packageName}".toUri()
                    )
                    intent.addCategory(Intent.CATEGORY_DEFAULT)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(context, intent, null)
                } else if (call.method == "recheckPermissions") {
                    if (allPermissionsGranted(context)) {
                        previewView.visibility = View.VISIBLE
                        bindUseCases(context)
                    } else {
                        previewView.visibility = View.GONE
                        reportViewInitialized(false)
                    }
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
        coroutineScope.launch {
            methodChannel.invokeMethod(
                "viewInitialized",
                JSONObject(mapOf("permissionsGranted" to permissionsGranted)).toString()
            )
        }
    }

    private fun reportCodeFound(code: String) {
        coroutineScope.launch {
            methodChannel.invokeMethod(
                "codeFound", JSONObject(
                    mapOf("value" to code)
                ).toString()
            )
        }
    }

    private fun bindUseCases(context: Context) {
        // If the ProcessCameraProvider is already resolved, rebind directly instead of
        // registering another addListener(). This prevents multiple pending listeners from
        // queuing up when bindUseCases() is called repeatedly (e.g. recheckPermissions),
        // which would each independently unbind/rebind and cause spurious state transitions.
        val resolvedProvider = cameraProvider
        if (resolvedProvider != null) {
            doBind(context, resolvedProvider)
            return
        }
        cameraProviderFuture.addListener({
            if (viewDisposed) return@addListener
            doBind(context, cameraProviderFuture.get() ?: return@addListener)
        }, ContextCompat.getMainExecutor(context))
    }

    private fun doBind(context: Context, provider: ProcessCameraProvider) {
        if (viewDisposed) return

        val lifecycleOwner = context as? LifecycleOwner ?: run {
            Log.e(TAG, "Context is not a LifecycleOwner, cannot bind camera")
            previewView.visibility = View.GONE
            reportViewInitialized(false)
            return
        }

        try {
            previewView.visibility = View.VISIBLE
            cameraProvider = provider

                // Reset StateChangeObserver so a CLOSED event from unbindAll() during
                // rebind does not send a spurious CameraClosed broadcast.
                stateChangeObserver.reset()
                cameraProvider?.unbindAll()

                // Resume scanning on rebind (e.g. recheckPermissions after a successful scan).
                // Without this, analysisPaused stays true from the previous scan and every
                // frame is silently dropped — the preview looks live but never finds a code.
                barcodeAnalyzer.analysisPaused = false

                val analysisResolution = Size(768, 1024)

                imageAnalysis = ImageAnalysis.Builder()
                    .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                    .setTargetResolution(analysisResolution)
                    .build()
                    .also {
                        it.setAnalyzer(cameraExecutor, barcodeAnalyzer)
                    }

                // Explicitly request continuous-picture AF via Camera2Interop.
                val previewBuilder = Preview.Builder()
                    .setTargetResolution(analysisResolution)
                    .also { builder ->
                        Camera2Interop.Extender(builder)
                            .setCaptureRequestOption(
                                CaptureRequest.CONTROL_AF_MODE,
                                CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE
                            )
                    }

                preview = previewBuilder.build()
                    .also {
                        it.surfaceProvider = previewView.surfaceProvider
                    }

                val camera = cameraProvider?.bindToLifecycle(
                    lifecycleOwner,
                    cameraSelector,
                    preview, imageAnalysis
                )

                // Update stable dimensions from the current layout, then keep them fresh.
                // Remove before adding to avoid duplicate registrations on repeated binds.
                stableViewWidth = previewView.width.toDouble().takeIf { it > 0 } ?: stableViewWidth
                stableViewHeight = previewView.height.toDouble().takeIf { it > 0 } ?: stableViewHeight
                barcodeAnalyzer.viewWidth = stableViewWidth
                barcodeAnalyzer.viewHeight = stableViewHeight
                previewView.viewTreeObserver.removeOnGlobalLayoutListener(layoutListener)
                previewView.viewTreeObserver.addOnGlobalLayoutListener(layoutListener)

                // Disable before enable to avoid accumulating duplicate sensor registrations
                // on repeated bindUseCases() calls (e.g. recheckPermissions).
                orientationEventListener.disable()
                orientationEventListener.enable()

                camera?.cameraInfo?.cameraState?.let {
                    it.removeObservers(lifecycleOwner)
                    it.observe(lifecycleOwner, stateChangeObserver)
                }

                reportViewInitialized(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to bind camera use cases: ${e.message}", e)
            previewView.visibility = View.GONE
            reportViewInitialized(false)
        }
    }

    private class BarcodeAnalyzer(
        private val overlaySizeFraction: Double,
        private val listener: BarcodeAnalyzerListener
    ) : ImageAnalysis.Analyzer {

        @Volatile var analysisPaused = false
        @Volatile var analyzedImagesCount = 0
        // Written from the main thread (layoutListener / bindUseCases), read from the camera
        // executor thread. @Volatile ensures visibility without boxing or lambda allocation.
        @Volatile var viewWidth = 0.0
        @Volatile var viewHeight = 0.0

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
                                TAG, "  row stride greater than image -> " +
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

                // Read @Volatile fields directly — no lambda call, no boxing, no allocation.
                val viewWidth = viewWidth
                val viewHeight = viewHeight

                val bitmapToProcess = if (overlaySizeFraction > 0 && fullSize.isCropSupported
                    && viewWidth > 0 && viewHeight > 0) {
                    // The PreviewView uses FILL_CENTER: scale uniformly to fill the view,
                    // center, and crop the overflow. Compute which buffer region corresponds
                    // to the overlay square shown on screen.
                    val isRotated = imageProxy.imageInfo.rotationDegrees.let {
                        it == 90 || it == 270
                    }
                    val displayedW = if (isRotated) imageProxy.height.toDouble() else imageProxy.width.toDouble()
                    val displayedH = if (isRotated) imageProxy.width.toDouble() else imageProxy.height.toDouble()
                    val scale = maxOf(viewWidth / displayedW, viewHeight / displayedH)
                    val overlaySidePx = min(viewWidth, viewHeight) * overlaySizeFraction
                    val cropWH = (overlaySidePx / scale)
                        .coerceAtMost(min(imageProxy.width.toDouble(), imageProxy.height.toDouble()))
                    val cropL = ((imageProxy.width - cropWH) / 2.0).coerceAtLeast(0.0)
                    val cropT = ((imageProxy.height - cropWH) / 2.0).coerceAtLeast(0.0)
                    if (analyzedImagesCount == 0) {
                        Log.v(TAG, "  rotation: ${imageProxy.imageInfo.rotationDegrees}")
                        Log.v(TAG, "  view: ${viewWidth}x${viewHeight}, displayed: ${displayedW}x${displayedH}")
                        Log.v(TAG, "  scale: $scale, overlaySide: $overlaySidePx, cropWH: $cropWH")
                        Log.v(TAG, "  buffer crop l:t:w:h $cropL:$cropT:$cropWH:$cropWH")
                    }
                    fullSize.crop(cropL.toInt(), cropT.toInt(), cropWH.toInt(), cropWH.toInt())
                } else {
                    if (analyzedImagesCount == 0) {
                        Log.v(TAG, "  bitmap l:t:w:h 0:0:${imageProxy.width}:${imageProxy.height} (full)")
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

        // Call before re-observing on a new camera session so that the CLOSED event
        // emitted by unbindAll() during rebind does not trigger a spurious broadcast.
        fun reset() { cameraOpened = false }

        override fun onChanged(value: CameraState) {
            Log.v(TAG, "Camera state changed to ${value.type}")

            if (value.type == CameraState.Type.OPEN) {
                cameraOpened = true
            }

            if (cameraOpened && value.type == CameraState.Type.CLOSED) {
                Log.v(TAG, "Camera closed")
                val stateChangedIntent =
                    Intent("com.yubico.authenticator.QRScannerView.CameraClosed").apply {
                        setPackage(context.packageName)
                    }
                context.sendBroadcast(stateChangedIntent)
                cameraOpened = false
            }
        }
    }

}
