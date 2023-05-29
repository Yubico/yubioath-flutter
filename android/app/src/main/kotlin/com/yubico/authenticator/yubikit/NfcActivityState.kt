package com.yubico.authenticator.yubikit

enum class NfcActivityState(val value: Int) {
    NOT_ACTIVE(0),
    READY(1),
    TAG_PRESENT(2),
    PROCESSING_STARTED(3),
    PROCESSING_FINISHED(4),
    PROCESSING_INTERRUPTED(5)
}