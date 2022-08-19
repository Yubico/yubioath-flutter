package com.yubico.authenticator.yubikit

import com.yubico.yubikit.core.YubiKeyConnection
import com.yubico.yubikit.core.YubiKeyDevice
import kotlin.coroutines.suspendCoroutine

suspend inline fun <reified C : YubiKeyConnection, T> YubiKeyDevice.withConnection(
    crossinline block: (C) -> T
): T = suspendCoroutine { continuation ->
    requestConnection(C::class.java) {
        continuation.resumeWith(runCatching {
            block(it.value)
        })
    }
}
