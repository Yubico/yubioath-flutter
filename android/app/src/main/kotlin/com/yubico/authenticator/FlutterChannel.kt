package com.yubico.authenticator

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

class FlutterChannel(
    messenger: BinaryMessenger,
    channel: String,
) {
    companion object {
        const val NULL = "null"
    }

    private val platform: MethodChannel = MethodChannel(messenger, channel)

    fun setHandler(
        scope: CoroutineScope,
        handler: suspend (method: String, args: Map<String, Any?>) -> String
    ) {
        platform.setMethodCallHandler { call, result ->
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

    suspend fun call(method: String, args: String = NULL): Any? =
        withContext(Dispatchers.Main) {
            suspendCoroutine { continuation ->
                platform.invokeMethod(
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
}