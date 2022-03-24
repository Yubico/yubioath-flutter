package com.yubico.authenticator.data.oath

import org.junit.Assert.assertEquals
import org.junit.Test

class ConversionKtTest {

    @Test
    fun computeUnlockOathSessionValue() {
        assertEquals(0, computeUnlockOathSessionValue(isUnlocked = false, isRemembered = false))
        assertEquals(1, computeUnlockOathSessionValue(isUnlocked = true, isRemembered = false))
        assertEquals(2, computeUnlockOathSessionValue(isUnlocked = false, isRemembered = true))
        assertEquals(3, computeUnlockOathSessionValue(isUnlocked = true, isRemembered = true))

    }
}