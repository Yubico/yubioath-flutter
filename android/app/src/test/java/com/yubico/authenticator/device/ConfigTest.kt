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
import com.yubico.yubikit.management.DeviceConfig
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.decodeFromJsonElement
import kotlinx.serialization.json.encodeToJsonElement
import kotlinx.serialization.json.jsonObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.mockito.Mockito


class ConfigTest {

    private fun serialize(c: Config) = jsonSerializer.encodeToJsonElement(c) as JsonObject
    private fun deserialize(s: String) =
        jsonSerializer.decodeFromJsonElement<Config>(Json.parseToJsonElement(s))


    @Test
    fun serialization() {
        // default arguments
        assertTrue(with(serialize(Config())) {
            val capabilities = getValue("enabled_capabilities")
            (keys.size == 4) and
                    (getValue("device_flags") == JsonNull) and
                    (getValue("challenge_response_timeout") == JsonNull) and
                    (getValue("auto_eject_timeout") == JsonNull) and
                    !capabilities.jsonObject.containsKey("usb") and
                    !capabilities.jsonObject.containsKey("nfc")
        })

        assertTrue(with(
            serialize(
                Config(
                    deviceFlags = 1,
                    challengeResponseTimeout = 255U,
                    autoEjectTimeout = 20U,
                    enabledCapabilities = Capabilities(usb = 123, nfc = 456)
                )
            )
        ) {
            val capabilities = getValue("enabled_capabilities")
            (keys.size == 4) and
                    (getValue("device_flags") == JsonPrimitive(1)) and
                    (getValue("challenge_response_timeout") == JsonPrimitive(255)) and
                    (getValue("auto_eject_timeout") == JsonPrimitive(20)) and
                    (capabilities.jsonObject.getValue("usb") == JsonPrimitive(123)) and
                    (capabilities.jsonObject.getValue("nfc") == JsonPrimitive(456))
        })
    }

    @Test
    fun deserialization() {
        assertEquals(
            deserialize(
                """
            { "device_flags": null,
              "challenge_response_timeout": null, 
              "auto_eject_timeout": null, 
              "enabled_capabilities": { "usb": null, "nfc": null } }
            """.trimIndent()
            ), Config()
        )

        assertEquals(
            deserialize(
                """
            { "device_flags": 123,
              "challenge_response_timeout": 123, 
              "auto_eject_timeout": 987, 
              "enabled_capabilities": { "usb": 202, "nfc": 303 } }
            """.trimIndent()
            ),
            Config(123, 123U, 987U, Capabilities(202, 303))
        )

    }

    private fun assertEqualAsInts(expected: Number?, actual: UByte?) =
        assertEquals(expected?.toInt(), actual?.toInt())

    private fun assertEqualAsInts(expected: Number?, actual: UShort?) =
        assertEquals(expected?.toInt(), actual?.toInt())

    @Test
    fun `deviceFlags value`() {
        val deviceConfig = Mockito.mock(DeviceConfig::class.java)

        Mockito.`when`(deviceConfig.deviceFlags).thenReturn(null)
        assertEquals(Config(deviceConfig).deviceFlags, null)

        Mockito.`when`(deviceConfig.deviceFlags).thenReturn(123)
        assertEquals(123, Config(deviceConfig).deviceFlags)
    }

    @Test
    fun `challengeResponseTimeout value`() {
        val deviceConfig = Mockito.mock(DeviceConfig::class.java)

        Mockito.`when`(deviceConfig.challengeResponseTimeout).thenReturn(null)
        assertEquals(Config(deviceConfig).challengeResponseTimeout, null)

        Mockito.`when`(deviceConfig.challengeResponseTimeout).thenReturn(0.toByte())
        assertEqualAsInts(0, Config(deviceConfig).challengeResponseTimeout)

        Mockito.`when`(deviceConfig.challengeResponseTimeout).thenReturn(128.toByte())
        assertEqualAsInts(128, Config(deviceConfig).challengeResponseTimeout)

        Mockito.`when`(deviceConfig.challengeResponseTimeout).thenReturn(255.toByte())
        assertEqualAsInts(255, Config(deviceConfig).challengeResponseTimeout)

        Mockito.`when`(deviceConfig.challengeResponseTimeout).thenReturn(256.toByte())
        assertEqualAsInts(0, Config(deviceConfig).challengeResponseTimeout)
    }

    @Test
    fun `autoEjectTimeout value`() {
        val deviceConfig = Mockito.mock(DeviceConfig::class.java)

        Mockito.`when`(deviceConfig.autoEjectTimeout).thenReturn(null)
        assertEquals(Config(deviceConfig).autoEjectTimeout, null)

        Mockito.`when`(deviceConfig.autoEjectTimeout).thenReturn(0.toShort())
        assertEqualAsInts(0, Config(deviceConfig).autoEjectTimeout)

        Mockito.`when`(deviceConfig.autoEjectTimeout).thenReturn(32768.toShort())
        assertEqualAsInts(32768, Config(deviceConfig).autoEjectTimeout)

        Mockito.`when`(deviceConfig.autoEjectTimeout).thenReturn(65535.toShort())
        assertEqualAsInts(65535, Config(deviceConfig).autoEjectTimeout)

        Mockito.`when`(deviceConfig.autoEjectTimeout).thenReturn(65536.toShort())
        assertEqualAsInts(0, Config(deviceConfig).autoEjectTimeout)
    }
}
