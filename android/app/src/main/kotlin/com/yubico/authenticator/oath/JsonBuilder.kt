package com.yubico.authenticator.oath

import kotlinx.serialization.json.Json

val jsonSerializer = Json {
    // allows us to use Credential as a key
    allowStructuredMapKeys = true
    // creates properties for default values
    encodeDefaults = true
}