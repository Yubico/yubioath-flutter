package com.yubico.authenticator

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import com.yubico.authenticator.device.Info
import com.yubico.yubikit.core.YubiKeyDevice

class MainViewModel : ViewModel() {
    private val _handleYubiKey = MutableLiveData(true)
    val handleYubiKey: LiveData<Boolean> = _handleYubiKey

    val yubiKeyDevice = MutableLiveData<YubiKeyDevice?>()

    private val _deviceInfo = MutableLiveData<Info?>()
    val deviceInfo: LiveData<Info?> = _deviceInfo

    fun setDeviceInfo(info: Info?) = _deviceInfo.postValue(info)
}
