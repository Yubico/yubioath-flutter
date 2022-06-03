package com.yubico.authenticator.yubikit

import com.yubico.authenticator.device.Info
import com.yubico.authenticator.logging.Log
import com.yubico.authenticator.management.model
import com.yubico.authenticator.oath.OathManager
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.android.transport.usb.UsbYubiKeyDevice
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.fido.FidoConnection
import com.yubico.yubikit.core.otp.OtpConnection
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.support.DeviceUtil
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine


suspend fun <T> withSmartCardConnection(
    device: YubiKeyDevice,
    block: (SmartCardConnection) -> T
) =
    suspendCoroutine<T> { continuation ->
        device.requestConnection(SmartCardConnection::class.java) {
            if (it.isError) {
                continuation.resumeWithException(IllegalStateException("Failed to get SmartCardConnection"))
            } else {
                continuation.resume(block(it.value))
            }
        }
    }

suspend fun <T> withOTPConnection(device: YubiKeyDevice, block: (OtpConnection) -> T) =
    suspendCoroutine<T> { continuation ->
        device.requestConnection(OtpConnection::class.java) {
            if (it.isError) {
                continuation.resumeWithException(IllegalStateException("Failed to get OtpConnection"))
            } else {
                continuation.resume(block(it.value))
            }
        }
    }

suspend fun <T> withFidoConnection(
    device: YubiKeyDevice,
    block: (FidoConnection) -> T
) =
    suspendCoroutine<T> { continuation ->
        device.requestConnection(FidoConnection::class.java) {
            if (it.isError) {
                continuation.resumeWithException(IllegalStateException("Failed to get FidoConnection"))
            } else {
                continuation.resume(block(it.value))
            }
        }
    }
