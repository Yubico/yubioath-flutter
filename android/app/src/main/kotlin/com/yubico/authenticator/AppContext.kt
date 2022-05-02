package com.yubico.authenticator

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import com.yubico.authenticator.api.Pigeon
import io.flutter.plugin.common.BinaryMessenger

enum class OperationContext(val value: Long) {
    Oath(0), Yubikey(1), Invalid(-1);

    companion object {
        fun getByValue(value: Long) = values().firstOrNull { it.value == value } ?: Invalid
    }
}

class AppContext(messenger: BinaryMessenger) : Pigeon.AppApi {
    private var _appContext = MutableLiveData(OperationContext.Oath)
    val appContext: LiveData<OperationContext> = _appContext

    init {
        Pigeon.AppApi.setup(messenger, this)
    }

    override fun setContext(subPageIndex: Long, result: Pigeon.Result<Void>) {
        _appContext.value = OperationContext.getByValue(subPageIndex)
        FlutterLog.d("App context is now $_appContext")
        result.success(null)
    }
}