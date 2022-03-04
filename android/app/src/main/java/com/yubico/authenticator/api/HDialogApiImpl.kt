package com.yubico.authenticator.api

import com.yubico.authenticator.MainViewModel

class HDialogApiImpl(private val viewModel : MainViewModel) : Pigeon.HDialogApi {
    override fun dialogClosed(result: Pigeon.Result<Void>?) {
        result?.run {
            viewModel.onDialogClosed(result)
        }
    }
}