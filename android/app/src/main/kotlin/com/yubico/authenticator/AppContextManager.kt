package com.yubico.authenticator

import com.yubico.yubikit.core.YubiKeyDevice

/**
 * Provides behavior to run when a YubiKey is inserted/tapped for a specific view of the app.
 */
interface AppContextManager {
    suspend fun processYubiKey(device: YubiKeyDevice)
    fun dispose()
}