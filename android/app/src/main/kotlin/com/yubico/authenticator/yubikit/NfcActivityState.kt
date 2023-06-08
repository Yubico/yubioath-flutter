package com.yubico.authenticator.yubikit

enum class NfcActivityState(val value: Int) {
    NOT_ACTIVE(0),
    READY(1),
    PROCESSING_STARTED(2),
    PROCESSING_FINISHED(3),
    PROCESSING_INTERRUPTED(4)
}