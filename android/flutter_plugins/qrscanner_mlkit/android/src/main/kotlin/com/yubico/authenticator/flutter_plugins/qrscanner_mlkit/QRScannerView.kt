package com.yubico.authenticator.flutter_plugins.qrscanner_mlkit

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Rect
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.widget.TextView
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.Preview
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
import org.json.JSONArray
import org.json.JSONObject
import java.nio.ByteBuffer
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.Result


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

data class BarcodeInfo(val rawData: String, val rect: Rect)
typealias BarcodeAnalyzerListener = (Result<List<BarcodeInfo>>) -> Unit

internal class QRScannerView(
    context: Context,
    id: Int,
    binaryMessenger: BinaryMessenger,
    private val permissionsResultRegistrar: PermissionsResultRegistrar,
    creationParams: Map<String?, Any?>?
) : PlatformView {

    private val uiThreadHandler = Handler(Looper.getMainLooper())

    companion object {
        const val TAG = "QRScannerView"

        // permission related
        const val PERMISSION_REQUEST_CODE = 1
        private val PERMISSIONS_TO_REQUEST =
            mutableListOf(
                Manifest.permission.CAMERA,
            ).toTypedArray()

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

    private val qrScannerView =
        LayoutInflater.from(context).inflate(R.layout.qr_scanner_view, null, false)
    private val previewView = qrScannerView.findViewById<PreviewView>(R.id.preview_view).apply {
        implementationMode = PreviewView.ImplementationMode.COMPATIBLE
    }
    private val infoView = qrScannerView.findViewById<TextView>(R.id.text_info).apply {
        setText(R.string.initializing)
    }

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

        if (context is Activity) {
            permissionsGranted = allPermissionsGranted(context)

            if (!permissionsGranted) {
                previewView.visibility = View.GONE
                infoView.setText(R.string.initializing)
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
                                        bindUseCases(context)
                                    } else {
                                        infoView.setText(R.string.permissions_missing)
                                    }
                                }

                                return true
                            }

                            return false
                        }
                    })

                requestPermissions(context)

            } else {
                bindUseCases(context)
            }
        }
    }

    private fun bindUseCases(context: Context) {
        cameraProviderFuture.addListener({
            cameraProvider = cameraProviderFuture.get()

            cameraProvider?.unbindAll()

            imageAnalyzer = ImageAnalysis.Builder()
                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                .build()
                .also {
                    it.setAnalyzer(cameraExecutor, BarcodeAnalyzer { analyzeResult ->
                        if (analyzeResult.isSuccess) {
                            analyzeResult.getOrNull()?.let { result ->
                                val codes = JSONArray(
                                    result.map { barcodeInfo ->
                                        JSONObject(
                                            mapOf(
                                                "value" to barcodeInfo.rawData,
                                                "location" to JSONArray(
                                                    listOf(
                                                        barcodeInfo.rect.left.toDouble(),
                                                        barcodeInfo.rect.top.toDouble(),
                                                        barcodeInfo.rect.right.toDouble(),
                                                        barcodeInfo.rect.bottom.toDouble()
                                                    )
                                                )
                                            )
                                        )
                                    }
                                )
                                uiThreadHandler.post {
                                    methodChannel.invokeMethod("codes", codes.toString())
                                }
                            }
                        }
                    })
                }

            preview = Preview.Builder()
                .build()
                .also {
                    it.setSurfaceProvider(previewView.surfaceProvider)
                }

            cameraProvider?.bindToLifecycle(
                context as LifecycleOwner,
                cameraSelector,
                preview, imageAnalyzer
            )

            previewView.visibility = View.VISIBLE

        }, ContextCompat.getMainExecutor(context))
    }

    private class BarcodeAnalyzer(private val listener: BarcodeAnalyzerListener) :
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

                val binary = BinaryBitmap(HybridBinarizer(source))
                val reader = MultiFormatReader()
                val result: com.google.zxing.Result = reader.decode(binary)
                val barcode = result.text
                Log.d(TAG, "Result text: ${result.text}")
                Log.d(TAG, "Result points: ")
                result.resultPoints?.map {
                    Log.d(TAG, "[${it.x}, ${it.y}]")
                }
                Log.d(TAG, "Result points: ${result.resultPoints}")
                listener.invoke(Result.success(listOf(BarcodeInfo(barcode, Rect(0, 0, 0, 0)))))
            } catch (_: NotFoundException) {
                // ignored: no code was found
            } finally {
                // important call
                imageProxy.close()
            }
        }
    }

}
