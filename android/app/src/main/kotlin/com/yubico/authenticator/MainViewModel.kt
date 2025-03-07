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

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import com.yubico.authenticator.OperationContext.entries
import com.yubico.authenticator.device.Info
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.management.Capability

enum class OperationContext(val value: Int) {
    Home(0),
    Oath(1),
    FidoU2f(2),
    FidoFingerprints(3),
    FidoPasskeys(4),
    YubiOtp(5),
    Piv(6),
    OpenPgp(7),
    HsmAuth(8),
    Management(9),
    Invalid(-1);

    companion object {
        fun getByValue(value: Int) = entries.firstOrNull { it.value == value } ?: Invalid

        fun Info.getSupportedContexts(): List<OperationContext> {

            val capabilitiesToContext = mapOf(
                Capability.OATH to listOf(Oath),
                Capability.FIDO2 to listOf(
                    FidoFingerprints, FidoPasskeys
                )
            )

            val operationContexts = mutableListOf(Home)

            val capabilities =
                (if (isNfc) config.enabledCapabilities.nfc else config.enabledCapabilities.usb)
                    ?: 0

            capabilitiesToContext.forEach { entry ->
                if (capabilities and entry.key.bit == entry.key.bit) {
                    operationContexts.addAll(entry.value)
                }
            }

            return operationContexts
        }

        fun getPreferredContext(contexts: List<OperationContext>): OperationContext {
            // custom sort
            for (context in listOf(
                Oath,
                FidoPasskeys,
                FidoFingerprints
            )) {
                if (context in contexts) {
                    return context
                }
            }

            return Home
        }


    }
}

class MainViewModel : ViewModel() {
    private var _appContext = MutableLiveData(OperationContext.Invalid)
    val appContext: LiveData<OperationContext> = _appContext
    fun setAppContext(appContext: OperationContext) {
        // Don't reset the context unless it actually changes
        if (appContext != _appContext.value) {
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
