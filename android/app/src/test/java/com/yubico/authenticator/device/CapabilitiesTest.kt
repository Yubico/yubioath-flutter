/*
 * Copyright (C) 2023 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.yubico.authenticator.device

import com.yubico.authenticator.jsonSerializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.decodeFromJsonElement
import kotlinx.serialization.json.encodeToJsonElement
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class CapabilitiesTest {

    companion object {
        private const val TAG_USB = "usb"
        private const val TAG_NFC = "nfc"
    }

    private fun serialize(c: Capabilities) = jsonSerializer.encodeToJsonElement(c) as JsonObject
    private fun deserialize(j: String) =
        jsonSerializer.decodeFromJsonElement<Capabilities>(Json.parseToJsonElement(j))

    @Test
    fun `serializes as JsonObject`() {
        assertTrue(jsonSerializer.encodeToJsonElement(Capabilities()) is JsonObject)
    }

    @Test
    fun serialization() {
        // test that keys are correct in serialized json
        assertTrue(serialize(Capabilities()).isEmpty())
        assertTrue(serialize(Capabilities(0)).containsKey(TAG_USB))
        assertFalse(serialize(Capabilities(0)).containsKey(TAG_NFC))
        assertTrue(serialize(Capabilities(usb = 0)).containsKey(TAG_USB))
        assertFalse(serialize(Capabilities(usb = 0)).containsKey(TAG_NFC))
        assertTrue(serialize(Capabilities(nfc = 0)).containsKey(TAG_NFC))
        assertFalse(serialize(Capabilities(nfc = 0)).containsKey(TAG_USB))
        assertTrue(with(serialize(Capabilities(0, 0))) {
            containsKey(TAG_NFC) and containsKey(TAG_USB)
        })

        // test that values are correct in serialized json
        assertTrue(serialize(Capabilities(usb = 100)).getValue(TAG_USB) == JsonPrimitive(100))
        assertTrue(serialize(Capabilities(nfc = 101)).getValue(TAG_NFC) == JsonPrimitive(101))
        assertTrue(with(serialize(Capabilities(nfc = 303, usb = 202))) {
            getValue(TAG_NFC) == JsonPrimitive(303) && getValue(TAG_USB) == JsonPrimitive(202)
        })
    }

    @Test
    fun deserialization() {
        assertTrue(with(deserialize("{}")) { (usb == null) and (nfc == null) })
        assertTrue(with(deserialize("""{"invalid": "x"}""")) { (usb == null) and (nfc == null) })
        assertTrue(with(deserialize("""{"usb": "x"}""")) { (usb == null) and (nfc == null) })
        assertTrue(with(deserialize("""{"usb": 10}""")) { (usb == 10) and (nfc == null) })
        assertTrue(with(deserialize("""{"nfc": 20}""")) { (usb == null) and (nfc == 20) })
        assertTrue(with(deserialize("""{"nfc": 20, "usb": "a" }""")) { (usb == null) and (nfc == null) })
        assertTrue(with(deserialize("""{"nfc": 25, "usb": 30 }""")) { (usb == 30) and (nfc == 25) })
        assertTrue(with(deserialize("""{"nfc": 0, "usb": 0 }""")) { (usb == 0) and (nfc == 0) })
    }
}