package com.yubico.authenticator

import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LiveData
import androidx.lifecycle.Observer
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.encodeToString
import java.io.Closeable
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

/**
 * Observes a LiveData value, sending each change to Flutter via an EventChannel.
 */
inline fun <reified T> LiveData<T>.streamTo(lifecycleOwner: LifecycleOwner, messenger: BinaryMessenger, channelName: String): Closeable {
    val channel = EventChannel(messenger, channelName)
    var sink: EventChannel.EventSink? = null

    channel.setStreamHandler(object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            sink = events
            events.success(value?.let(jsonSerializer::encodeToString) ?: NULL)
        }

        override fun onCancel(arguments: Any?) {
            sink = null
        }
    })

    val observer = Observer<T> {
        sink?.success(it?.let(jsonSerializer::encodeToString) ?: NULL)
    }
    observe(lifecycleOwner, observer)

    return Closeable {
        removeObserver(observer)
        channel.setStreamHandler(null)
    }
}

typealias MethodHandler = suspend (method: String, args: Map<String, Any?>) -> String

/**
 * Coroutine-based handing of MethodChannel methods called from Flutter.
 */
fun MethodChannel.setHandler(scope: CoroutineScope, handler: MethodHandler) {
    setMethodCallHandler { call, result ->
        // N.B. Arguments from Flutter are passed as a Map of basic types. We may want to
        // consider JSON encoding if we need to pass more complex structures.
        // Return values are always JSON strings.
        val args = call.arguments<Map<String, Any?>>() ?: mapOf()
        scope.launch {
            try {
                val response = handler.invoke(call.method, args)
                result.success(response)
            } catch (notImplemented: NotImplementedError) {
                result.notImplemented()
            } catch (error: Throwable) {
                result.error(
                    error.javaClass.simpleName,
                    error.toString(),
                    "Cause: " + error.cause + ", Stacktrace: " + android.util.Log.getStackTraceString(
                        error
                    )
                )
            }
        }
    }
}

/**
 * Coroutine-based method invocation to call a Flutter method and get a result.
 */
suspend fun MethodChannel.invoke(method: String, args: Any?): Any? =
    withContext(Dispatchers.Main) {
        suspendCoroutine { continuation ->
            invokeMethod(
                method,
                args,
                object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        continuation.resume(result)
                    }

                    override fun error(
                        errorCode: String,
                        errorMessage: String?,
                        errorDetails: Any?
                    ) {
                        continuation.resumeWithException(Exception("$errorCode: $errorMessage - $errorDetails"))
                    }

                    override fun notImplemented() {
                        continuation.resumeWithException(NotImplementedError("Method not implemented: $method"))
                    }
                })
        }
    }