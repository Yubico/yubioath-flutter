package com.yubico.authenticator

import com.yubico.yubikit.core.YubiKeyDevice

interface AppContextManager {
    suspend fun processYubiKey(device: YubiKeyDevice)
}