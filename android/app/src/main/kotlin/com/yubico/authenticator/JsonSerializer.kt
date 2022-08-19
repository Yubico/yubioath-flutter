package com.yubico.authenticator

import kotlinx.serialization.json.Json

const val NULL = "null"

val jsonSerializer = Json {
    // creates properties for default values
    encodeDefaults = true
}