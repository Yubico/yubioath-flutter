package com.yubico.authenticator.data.oath

import org.junit.Assert.assertEquals
import org.junit.Test

class ConversionKtTest {

    @Test
    fun computeUnlockOathSessionValue() {
        assertEquals(0, computeUnlockOathSessionValue(isLocked = false, isRemembered = false))
        assertEquals(1, computeUnlockOathSessionValue(isLocked = true, isRemembered = false))
        assertEquals(2, computeUnlockOathSessionValue(isLocked = false, isRemembered = true))
        assertEquals(3, computeUnlockOathSessionValue(isLocked = true, isRemembered = true))

    }
}