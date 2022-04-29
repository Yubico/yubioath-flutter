package com.yubico.authenticator.oath

import com.yubico.authenticator.MainViewModel
import com.yubico.authenticator.api.Pigeon.OathApi
import com.yubico.authenticator.api.Pigeon.Result
import com.yubico.authenticator.api.Pigeon.UnlockResponse

class OathApiImpl(private val viewModel: MainViewModel) : OathApi {

    override fun reset(result: Result<Void>) {
        viewModel.resetOathSession(result)
    }

    override fun unlock(
        password: String,
        remember: Boolean,
        result: Result<UnlockResponse>
    ) {
        viewModel.unlockOathSession(password, remember, result)
    }

    override fun setPassword(
        currentPassword: String?,
        newPassword: String,
        result: Result<Void>
    ) {
        viewModel.setOathPassword(currentPassword, newPassword, result)
    }

    override fun unsetPassword(currentPassword: String, result: Result<Void>) {
        viewModel.unsetOathPassword(currentPassword, result)
    }

    override fun forgetPassword(result: Result<Void>) {
        viewModel.forgetPassword(result)
    }

    override fun addAccount(
        uri: String,
        requireTouch: Boolean,
        result: Result<String>
    ) {
        viewModel.addAccount(uri, requireTouch, result)
    }

    override fun renameAccount(uri: String, name: String, issuer: String?, result: Result<String>) {
        viewModel.renameCredential(uri, name, issuer, result)
    }

    override fun deleteAccount(uri: String, result: Result<Void>) {
        viewModel.deleteAccount(uri, result)
    }

    override fun refreshCodes(result: Result<String>) {
        viewModel.refreshOathCodes(result)
    }

    override fun calculate(uri: String, result: Result<String>) {
        viewModel.calculate(uri, result)
    }

}