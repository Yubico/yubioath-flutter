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
    private var _appContext = MutableLiveData(OperationContext.Oath)
    val appContext: LiveData<OperationContext> = _appContext
    fun setAppContext(appContext: OperationContext) {
        // Don't reset the context unless it actually changes
        if(appContext != _appContext.value) {
            _appContext.postValue(appContext)
        }
    }

    private val _connectedYubiKey = MutableLiveData<UsbYubiKeyDevice?>()
    val connectedYubiKey: LiveData<UsbYubiKeyDevice?> = _connectedYubiKey
    fun setConnectedYubiKey(device: UsbYubiKeyDevice, onDisconnect: () -> Unit ) {
        _connectedYubiKey.postValue(device)
        device.setOnClosed {
            _connectedYubiKey.postValue(null)
            onDisconnect()
        }
    }

    private val _deviceInfo = MutableLiveData<Info?>()
    val deviceInfo: LiveData<Info?> = _deviceInfo

    fun setDeviceInfo(info: Info?) = _deviceInfo.postValue(info)
}
