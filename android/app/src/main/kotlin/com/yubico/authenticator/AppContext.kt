package com.yubico.authenticator

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.yubico.authenticator.logging.Log
import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.CoroutineScope

class AppContext(messenger: BinaryMessenger, coroutineScope: CoroutineScope, private val appViewModel: MainViewModel)  {
    private val channel = FlutterChannel(messenger, "android.state.appContext")

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
        appViewModel.setContext(appContext)
        Log.d(TAG, "App context is now ${appContext}")
        return FlutterChannel.NULL
    }

    companion object {
        const val TAG = "appContext"
    }
}