package com.yubico.authenticator.flutter_plugins.qrscanner_zxing

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.widget.TextView
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.zxing.*
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
    id: Int,
    binaryMessenger: BinaryMessenger,
    private val permissionsResultRegistrar: PermissionsResultRegistrar,
    creationParams: Map<String?, Any?>?
) : PlatformView {

    private val uiThreadHandler = Handler(Looper.getMainLooper())

    private var marginPct: Double? = null

    companion object {
        const val TAG = "QRScannerView"

        // permission related
        const val PERMISSION_REQUEST_CODE = 1
        private val PERMISSIONS_TO_REQUEST =
            mutableListOf(
                Manifest.permission.CAMERA,
            ).toTypedArray()

        // view related
        private const val QR_SCANNER_ASPECT_RATIO = AspectRatio.RATIO_4_3

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
    }
    private val infoText = qrScannerView.findViewById<TextView>(R.id.info_text)

    private val cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
    private var cameraProvider: ProcessCameraProvider? = null
    private val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

    private var imageAnalyzer: ImageAnalysis? = null
    private var preview: Preview? = null

    override fun getView(): View {
        return qrScannerView
    }

    override fun dispose() {
        cameraProvider?.unbindAll()
        preview = null
        imageAnalyzer = null
        cameraExecutor.shutdown()
        Log.d(TAG, "View disposed")
    }

    private val methodChannel: MethodChannel = MethodChannel(binaryMessenger, CHANNEL_NAME)
    private var permissionsGranted = false

    init {

        // read margin parameter
        // only use it if it has reasonable value
        if (creationParams?.get("margin") is Number) {
            val marginValue = creationParams["margin"] as Number
            if (marginValue.toDouble() > 0.0 && marginValue.toDouble() < 45) {
                marginPct = marginValue.toDouble()
            }
        }

        if (context is Activity) {
            permissionsGranted = allPermissionsGranted(context)

            if (!permissionsGranted) {
                requestPermissionsFromUser(context)
            } else {
                bindUseCases(context)
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
                                infoText.visibility = View.GONE
                                bindUseCases(activity)
                            } else {
                                previewView.visibility = View.GONE
                                infoText.visibility = View.VISIBLE
                                infoText.setText(R.string.please_grant_permissions)
                            }
                        } else {
                            previewView.visibility = View.GONE
                            infoText.visibility = View.VISIBLE
                            infoText.setText(R.string.please_grant_permissions)
                        }
                        return true
                    }

                    return false
                }
            })

        requestPermissions(activity)
    }

    private fun bindUseCases(context: Context) {
        cameraProviderFuture.addListener({
            previewView.visibility = View.VISIBLE
            cameraProvider = cameraProviderFuture.get()

            cameraProvider?.unbindAll()

            imageAnalyzer = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .setTargetAspectRatio(QR_SCANNER_ASPECT_RATIO)
                .build()
                .also {
                    it.setAnalyzer(cameraExecutor, BarcodeAnalyzer(marginPct) { analyzeResult ->
                        if (analyzeResult.isSuccess) {
                            analyzeResult.getOrNull()?.let { result ->
                                uiThreadHandler.post {
                                    methodChannel.invokeMethod(
                                        "codeFound", JSONObject(
                                            mapOf("value" to result)
                                        ).toString()
                                    )
                                }
                            }
                        }
                    })
                }

            preview = Preview.Builder()
                .setTargetAspectRatio(QR_SCANNER_ASPECT_RATIO)
                .build()
                .also {
                    it.setSurfaceProvider(previewView.surfaceProvider)
                }

            cameraProvider?.bindToLifecycle(
                context as LifecycleOwner,
                cameraSelector,
                preview, imageAnalyzer
            )
        }, ContextCompat.getMainExecutor(context))
    }

    private class BarcodeAnalyzer(
        private val marginPct: Double?,
        private val listener: BarcodeAnalyzerListener
    ) :
        ImageAnalysis.Analyzer {

        private fun ByteBuffer.toByteArray(): ByteArray {
            rewind()
            val data = ByteArray(remaining())
            get(data)
            return data
        }

        override fun analyze(imageProxy: ImageProxy) {
            try {
                val buffer = imageProxy.planes[0].buffer
                val intArray = buffer.toByteArray().map { it.toInt() }.toIntArray()

                val source: LuminanceSource =
                    RGBLuminanceSource(imageProxy.width, imageProxy.height, intArray)

                val fullSize = BinaryBitmap(HybridBinarizer(source))

                val bitmapToProcess = if (marginPct != null) {
                    val shorterDim = min(imageProxy.width, imageProxy.height)
                    val cropMargin = marginPct * 0.01 * shorterDim
                    val cropWH = shorterDim - 2.0 * cropMargin
                    val cropT = (imageProxy.height - cropWH) / 2.0
                    val cropL = (imageProxy.width - cropWH) / 2.0
                    fullSize.crop(
                        cropL.toInt(),
                        cropT.toInt(),
                        cropWH.toInt(),
                        cropWH.toInt()
                    )
                } else {
                    fullSize
                }

                val reader = MultiFormatReader()
                val result: com.google.zxing.Result = reader.decode(bitmapToProcess)
                Log.d(TAG, "Result text: ${result.text}")
                listener.invoke(Result.success(result.text))
            } catch (_: NotFoundException) {
                // ignored: no code was found
            } finally {
                // important call
                imageProxy.close()
            }
        }
    }

}
