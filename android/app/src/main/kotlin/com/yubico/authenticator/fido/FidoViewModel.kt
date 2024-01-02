package com.yubico.authenticator.fido

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel

import com.yubico.authenticator.fido.data.Session

class FidoViewModel : ViewModel() {
    private val _sessionState = MutableLiveData<Session?>()
    val sessionState: LiveData<Session?> = _sessionState

    fun setSessionState(sessionState: Session?) {
        _sessionState.postValue(sessionState)
    }
}