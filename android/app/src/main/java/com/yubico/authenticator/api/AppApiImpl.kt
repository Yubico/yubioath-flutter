package com.yubico.authenticator.api

import com.yubico.authenticator.MainViewModel
import com.yubico.authenticator.OperationContext

class AppApiImpl(private val modelView: MainViewModel) : Pigeon.AppApi {

    override fun setContext(subPageIndex: Long, result: Pigeon.Result<Void>) {
        val contextValue = OperationContext.getByValue(subPageIndex)
        if (contextValue == OperationContext.Invalid) {
            // returning success is all we can do here
            result.success(null)
            return
        }

        modelView.setContext(contextValue)
        result.success(null)
    }
}