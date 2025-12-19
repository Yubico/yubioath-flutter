/*
 * Copyright (C) 2022-2025 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.yubico.authenticator

import android.app.Application
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.yubico.authenticator.OperationContext.entries
import com.yubico.authenticator.device.Info
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.management.Capability
import com.yubico.yubikit.management.FormFactor

enum class OperationContext(val value: Int) {
    Default(-1),
    Home(0),
    Oath(1),
    FidoU2f(2),
    FidoFingerprints(3),
    FidoPasskeys(4),
    Piv(5),
    YubiOtp(6),
    Settings(7),
    OpenPgp(8),
    HsmAuth(9),
    Management(10);

    companion object {
        fun getByValue(value: Int) = entries.firstOrNull { it.value == value } ?: Default

        fun Info.getSupportedContexts(): List<OperationContext> {
            val capabilitiesToContext = mapOf(
                Capability.OATH to Oath,
                Capability.PIV to Piv,
                Capability.FIDO2 to FidoPasskeys
            )

            val operationContexts = mutableListOf(Home)

            val capabilities =
                (if (isNfc) config.enabledCapabilities.nfc else config.enabledCapabilities.usb)
                    ?: 0

            capabilitiesToContext.forEach { entry ->
                if (capabilities and entry.key.bit == entry.key.bit) {
                    operationContexts.add(entry.value)
                }
            }

            if (formFactor in listOf(FormFactor.USB_C_BIO.value, FormFactor.USB_A_BIO.value)) {
                operationContexts.add(FidoFingerprints)
            }
            operationContexts.add(Management)

            return operationContexts
        }
    }
}

data class AppContext(val appContext: OperationContext, val notify: Boolean = false)

class MainViewModel(application: Application) : ViewModel() {

    private val appPreferences = AppPreferences(application)

    private var _appContext = MutableLiveData(AppContext(appPreferences.appContext))
    val appContext: LiveData<AppContext> = _appContext
    fun setAppContext(appContext: AppContext) {
        // Don't reset the context unless it actually changes
        if (appContext.appContext != _appContext.value?.appContext) {
            _appContext.postValue(appContext)
        }
    }

    private val _connectedYubiKey = MutableLiveData<UsbYubiKeyDevice?>()
    val connectedYubiKey: LiveData<UsbYubiKeyDevice?> = _connectedYubiKey
    fun setConnectedYubiKey(device: UsbYubiKeyDevice, onDisconnect: () -> Unit) {
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

class MainViewModelFactory(private val application: Application) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(MainViewModel::class.java)) {
            @Suppress("UNCHECKED_CAST")
            return MainViewModel(application) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}
