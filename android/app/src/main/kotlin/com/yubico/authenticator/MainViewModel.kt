package com.yubico.authenticator

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import com.yubico.authenticator.device.Info
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice

enum class OperationContext(val value: Int) {
    Oath(0), Yubikey(1), Invalid(-1);

    companion object {
        fun getByValue(value: Int) = values().firstOrNull { it.value == value } ?: Invalid
    }
}

class MainViewModel : ViewModel() {
    private val _handleYubiKey = MutableLiveData(true)
    val handleYubiKey: LiveData<Boolean> = _handleYubiKey

    private var _appContext = MutableLiveData(OperationContext.Oath)
    val appContext: LiveData<OperationContext> = _appContext
    fun setAppContext(appContext: OperationContext) = _appContext.postValue(appContext)

    private val _connectedYubiKey = MutableLiveData<UsbYubiKeyDevice?>()
    val connectedYubiKey: LiveData<UsbYubiKeyDevice?> = _connectedYubiKey
    fun setConnectedYubiKey(device: UsbYubiKeyDevice) {
        _connectedYubiKey.postValue(device)
        device.setOnClosed { _connectedYubiKey.postValue(null) }
    }

    private val _deviceInfo = MutableLiveData<Info?>()
    val deviceInfo: LiveData<Info?> = _deviceInfo

    fun setDeviceInfo(info: Info?) = _deviceInfo.postValue(info)
}
