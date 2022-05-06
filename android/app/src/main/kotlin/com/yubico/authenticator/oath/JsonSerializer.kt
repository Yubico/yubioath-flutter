package com.yubico.authenticator.oath

import kotlinx.serialization.json.Json

val jsonSerializer = Json {
    // creates properties for default values
    encodeDefaults = true
}