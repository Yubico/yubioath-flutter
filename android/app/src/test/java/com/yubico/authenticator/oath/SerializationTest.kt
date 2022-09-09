package com.yubico.authenticator.oath

import com.yubico.authenticator.device.Version
import com.yubico.authenticator.jsonSerializer
import com.yubico.authenticator.oath.OathTestHelper.code
import com.yubico.authenticator.oath.OathTestHelper.hotp
import com.yubico.authenticator.oath.OathTestHelper.totp
import kotlinx.serialization.json.*
import org.junit.Assert.*
import org.junit.Test

class SerializationTest {

    private val session = Model.Session(
        "device",
        Version(1, 2, 3),
        isAccessKeySet = false,
        isRemembered = false,
        isLocked = false
    )

    @Test
    fun `serialization settings`() {
        assertTrue(jsonSerializer.configuration.encodeDefaults)
        assertFalse(jsonSerializer.configuration.allowStructuredMapKeys)
    }

    @Test
    fun `session json type`() {
        val jsonElement = jsonSerializer.encodeToJsonElement(session)
        assertTrue(jsonElement is JsonObject)
    }

    @Test
    fun `session json property names`() {
        val jsonObject : JsonObject = jsonSerializer.encodeToJsonElement(session) as JsonObject
        assertTrue(jsonObject.containsKey("device_id"))
        assertTrue(jsonObject.containsKey("has_key"))
        assertTrue(jsonObject.containsKey("remembered"))
        assertTrue(jsonObject.containsKey("locked"))
        assertTrue(jsonObject.containsKey("keystore"))
    }

    @Test
    fun `keystore is unknown`() {
        val jsonObject : JsonObject = jsonSerializer.encodeToJsonElement(session) as JsonObject
        assertEquals("unknown", jsonObject["keystore"]?.jsonPrimitive?.content)
    }

    @Test
    fun `credential json type`() {
        val c = totp()

        val jsonElement = jsonSerializer.encodeToJsonElement(c)
        assertTrue(jsonElement is JsonObject)
    }

    @Test
    fun `credential json property names`() {
        val c = totp()

        val jsonObject : JsonObject = jsonSerializer.encodeToJsonElement(c) as JsonObject

        assertTrue(jsonObject.containsKey("device_id"))
        assertTrue(jsonObject.containsKey("id"))
        assertTrue(jsonObject.containsKey("oath_type"))
        assertTrue(jsonObject.containsKey("period"))
        assertTrue(jsonObject.containsKey("issuer"))
        assertTrue(jsonObject.containsKey("name"))
        assertTrue(jsonObject.containsKey("touch_required"))
    }

    @Test
    fun `code json type`() {
        val c = code()

        val jsonElement = jsonSerializer.encodeToJsonElement(c)
        assertTrue(jsonElement is JsonObject)
    }

    @Test
    fun `code json property names`() {
        val c = code()

        val jsonObject : JsonObject = jsonSerializer.encodeToJsonElement(c) as JsonObject

        assertTrue(jsonObject.containsKey("value"))
        assertTrue(jsonObject.containsKey("valid_from"))
        assertTrue(jsonObject.containsKey("valid_to"))
    }

    @Test
    fun `code json content`() {
        val c = code(value = "001122", from = 1000, to = 2000)

        val jsonObject : JsonObject = jsonSerializer.encodeToJsonElement(c) as JsonObject

        assertEquals(JsonPrimitive(1000), jsonObject["valid_from"])
        assertEquals(JsonPrimitive(2000), jsonObject["valid_to"])
        assertEquals(JsonPrimitive("001122"), jsonObject["value"])
    }

    @Test
    fun `credentials json type`() {
        val l = listOf(
            Model.CredentialWithCode(totp(), code()), Model.CredentialWithCode(hotp(), code()),
        )

        val jsonElement = jsonSerializer.encodeToJsonElement(l)
        assertTrue(jsonElement is JsonArray)
    }

    @Test
    fun `credentials json size`() {
        val l1 = listOf<Model.CredentialWithCode>()
        val jsonElement1 = jsonSerializer.encodeToJsonElement(l1) as JsonArray
        assertEquals(0, jsonElement1.size)

        val l2 = listOf(
            Model.CredentialWithCode(totp(), code()), Model.CredentialWithCode(hotp(), code()),
        )
        val jsonElement2 = jsonSerializer.encodeToJsonElement(l2) as JsonArray
        assertEquals(2, jsonElement2.size)
    }

}