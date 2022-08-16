package com.yubico.authenticator

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.yubico.authenticator.logging.Log
import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.CoroutineScope

enum class OperationContext(val value: Int) {
    Oath(0), Yubikey(1), Invalid(-1);

    companion object {
        fun getByValue(value: Int) = values().firstOrNull { it.value == value } ?: Invalid
    }
}

class AppContext(messenger: BinaryMessenger, private val coroutineScope: CoroutineScope)  {
    private val channel =
        FlutterChannel(messenger, "com.yubico.authenticator.channel.appContext")
    private var _appContext = MutableLiveData(OperationContext.Oath)
    val appContext: LiveData<OperationContext> = _appContext

    init {
        channel.setHandler(coroutineScope) { method, args ->
            when (method) {
                "setContext" -> setContext(args["index"] as Int)
                else -> throw NotImplementedError()
            }
        }
    }


    private suspend fun setContext(subPageIndex: Int): String {
        _appContext.value = OperationContext.getByValue(subPageIndex)
        Log.d(TAG, "App context is now $_appContext")
        return FlutterChannel.NULL
    }

    companion object {
        const val TAG = "appContext"
    }
}