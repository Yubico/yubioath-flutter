package com.yubico.authenticator.fido

const val dialogDescriptionOathIndex = 200

enum class FidoActionDescription(private val value: Int) {
    Reset(0),
    Unlock(1),
    SetPin(2),
    ActionFailure(3);

    val id: Int
        get() = value + dialogDescriptionOathIndex
}