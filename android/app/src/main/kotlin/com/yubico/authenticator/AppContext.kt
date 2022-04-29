package com.yubico.authenticator

import com.yubico.authenticator.api.Pigeon
import com.yubico.yubikit.core.Logger

enum class OperationContext(val value: Long) {
    Oath(0), Yubikey(1), Invalid(-1);

    companion object {
        fun getByValue(value: Long) = values().firstOrNull { it.value == value } ?: Invalid
    }
}

class AppContext : Pigeon.AppApi {

    private var _operationContext = OperationContext.Oath

    fun getContext() : OperationContext {
        return _operationContext
    }

    override fun setContext(subPageIndex: Long, result: Pigeon.Result<Void>) {
        _operationContext = OperationContext.getByValue(subPageIndex)
        Logger.d("Operation context is now $_operationContext")
        result.success(null)
    }

}