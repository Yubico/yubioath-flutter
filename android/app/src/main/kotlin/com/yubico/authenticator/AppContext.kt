package com.yubico.authenticator

import com.yubico.authenticator.logging.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope

class AppContext(messenger: BinaryMessenger, coroutineScope: CoroutineScope, private val appViewModel: MainViewModel)  {
    private val channel = MethodChannel(messenger, "android.state.appContext")

    init {
        channel.setHandler(coroutineScope) { method, args ->
            when (method) {
                "setContext" -> setContext(args["index"] as Int)
                else -> throw NotImplementedError()
            }
        }
    }

    private suspend fun setContext(subPageIndex: Int): String {
        val appContext = OperationContext.getByValue(subPageIndex)
        appViewModel.setAppContext(appContext)
        Log.d(TAG, "App context is now $appContext")
        return NULL
    }

    companion object {
        const val TAG = "appContext"
    }
}