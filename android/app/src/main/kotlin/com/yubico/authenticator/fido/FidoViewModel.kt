package com.yubico.authenticator.fido

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel

import com.yubico.authenticator.fido.data.Session
import com.yubico.authenticator.fido.data.FidoCredential

class FidoViewModel : ViewModel() {
    private val _sessionState = MutableLiveData<Session?>()
    val sessionState: LiveData<Session?> = _sessionState

    fun setSessionState(sessionState: Session?) {
        _sessionState.postValue(sessionState)
    }

    private val _credentials = MutableLiveData<List<FidoCredential>>()
    val credentials: LiveData<List<FidoCredential>> = _credentials

    fun updateCredentials(credentials: List<FidoCredential>) {
        _credentials.postValue(credentials)
    }
}