package com.yubico.authenticator.api

import com.yubico.authenticator.MainViewModel

class OathApiImpl(private val viewModel: MainViewModel) : Pigeon.OathApi {

    override fun reset(result: Pigeon.Result<Void>) {
        viewModel.resetOathSession(result)
    }

    override fun unlock(
        password: String,
        remember: Boolean,
        result: Pigeon.Result<Boolean>
    ) {
        viewModel.unlockOathSession(password, remember, result)
    }

    override fun setPassword(
        currentPassword: String?,
        newPassword: String,
        result: Pigeon.Result<Void>
    ) {
        viewModel.setOathPassword(currentPassword, newPassword, result)
    }

    override fun unsetPassword(currentPassword: String, result: Pigeon.Result<Void>) {
        viewModel.unsetOathPassword(currentPassword, result)
    }

    override fun forgetPassword(result: Pigeon.Result<Void>) {
        viewModel.forgetPassword(result)
    }

    override fun addAccount(
        uri: String,
        requireTouch: Boolean,
        result: Pigeon.Result<String>
    ) {
        viewModel.addAccount(uri, requireTouch, result)
    }

    override fun renameAccount(uri: String, name: String, issuer: String?, result: Pigeon.Result<String>) {
        viewModel.renameCredential(uri, name, issuer, result)
    }

    override fun deleteAccount(uri: String, result: Pigeon.Result<Void>) {
        viewModel.deleteAccount(uri, result)
    }

    override fun refreshCodes(result: Pigeon.Result<String>) {
        viewModel.refreshOathCodes(result)
    }

    override fun calculate(uri: String, result: Pigeon.Result<String>) {
        viewModel.calculate(uri, result)
    }

}