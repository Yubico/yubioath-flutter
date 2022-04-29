package com.yubico.authenticator

import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.util.Result

data class YubiKeyAction(
    val message: String,
    val action: suspend (Result<YubiKeyDevice, Exception>) -> Unit
)