package com.yubico.authenticator.oath

import com.yubico.authenticator.oath.OathTestHelper.code
import com.yubico.authenticator.oath.OathTestHelper.hotp
import com.yubico.authenticator.oath.OathTestHelper.totp
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.encodeToJsonElement
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class SerializationTest {

    @Test
    fun `serialization settings`() {
        assertTrue(jsonSerializer.configuration.encodeDefaults)
        assertTrue(jsonSerializer.configuration.allowStructuredMapKeys)
    }

    @Test
    fun `session json type`() {
        val s = Model.Session()

        val jsonElement = jsonSerializer.encodeToJsonElement(s)
        assertTrue(jsonElement is JsonObject)
    }

    @Test
    fun `session json property names`() {
        val s = Model.Session()

        val jsonObject : JsonObject = jsonSerializer.encodeToJsonElement(s) as JsonObject
        assertTrue(jsonObject.containsKey("device_id"))
        assertTrue(jsonObject.containsKey("has_key"))
        assertTrue(jsonObject.containsKey("remembered"))
        assertTrue(jsonObject.containsKey("locked"))
        assertTrue(jsonObject.containsKey("keystore"))
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
    fun `credentials json type`() {
        val m = mapOf(totp() to code(), hotp() to code())

        val jsonElement = jsonSerializer.encodeToJsonElement(m)
        assertTrue(jsonElement is JsonArray)
    }

    @Test
    fun `credentials json size`() {
        val m1 = mapOf<Model.Credential, Model.Code?>()
        val jsonElement1 = jsonSerializer.encodeToJsonElement(m1) as JsonArray
        assertEquals(0, jsonElement1.size)

        val m2 = mapOf(totp() to code(), hotp() to code())
        val jsonElement2 = jsonSerializer.encodeToJsonElement(m2) as JsonArray
        assertEquals(4, jsonElement2.size)
    }

    @Test
    fun `credentials json content`() {
        val m = mapOf(totp() to code())
        val jsonElement = jsonSerializer.encodeToJsonElement(m) as JsonArray

        // the first element is Credential which has device_id property
        assertTrue((jsonElement[0] as JsonObject).containsKey("device_id"))

        // the second element is Credential which has value property
        assertTrue((jsonElement[1] as JsonObject).containsKey("value"))
    }
}