package com.yubico.authenticator

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import com.yubico.yubikit.core.YubiKeyDevice

class MainViewModel : ViewModel() {

    private val _handleYubiKey = MutableLiveData(true)
    val handleYubiKey: LiveData<Boolean> = _handleYubiKey

    val yubiKeyDevice = MutableLiveData<YubiKeyDevice?>()
}
