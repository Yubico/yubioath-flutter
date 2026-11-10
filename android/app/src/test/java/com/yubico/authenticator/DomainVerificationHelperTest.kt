/*
 * Copyright (C) 2026 Yubico.
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

package com.yubico.authenticator

import android.content.pm.verify.domain.DomainVerificationUserState.DOMAIN_STATE_NONE
import android.content.pm.verify.domain.DomainVerificationUserState.DOMAIN_STATE_SELECTED
import android.content.pm.verify.domain.DomainVerificationUserState.DOMAIN_STATE_VERIFIED
import com.yubico.authenticator.DomainVerificationHelper.Status
import org.junit.Assert.assertEquals
import org.junit.Test

class DomainVerificationHelperTest {

    @Test
    fun `wire values are unchanged`() {
        // Decoded by `getDomainVerificationStatus` in lib/android/app_methods.dart, which
        // test/android/nfc_link_notice_test.dart pins to the same strings.
        assertEquals(
            mapOf(
                "UNSUPPORTED" to "unsupported",
                "VERIFIED" to "verified",
                "SELECTED" to "selected",
                "NONE" to "none"
            ),
            Status.entries.associate { it.name to it.value }
        )
    }

    @Test
    fun `verified domain needs no action`() {
        assertEquals(
            Status.VERIFIED,
            DomainVerificationHelper.statusOf(true, DOMAIN_STATE_VERIFIED)
        )
    }

    @Test
    fun `domain added by the user needs no action`() {
        assertEquals(
            Status.SELECTED,
            DomainVerificationHelper.statusOf(true, DOMAIN_STATE_SELECTED)
        )
    }

    @Test
    fun `unverified domain is not handled`() {
        // What a build signed with a key missing from assetlinks.json reports.
        assertEquals(Status.NONE, DomainVerificationHelper.statusOf(true, DOMAIN_STATE_NONE))
    }

    @Test
    fun `turning off open supported links overrides every host state`() {
        for (state in listOf(DOMAIN_STATE_NONE, DOMAIN_STATE_SELECTED, DOMAIN_STATE_VERIFIED)) {
            assertEquals(
                "host state $state",
                Status.NONE,
                DomainVerificationHelper.statusOf(false, state)
            )
        }
    }

    @Test
    fun `unknown host state is treated as not handled`() {
        // Future states fall to NONE so the user is pointed at the settings page rather than
        // silently left with tap actions that do nothing.
        assertEquals(Status.NONE, DomainVerificationHelper.statusOf(true, 1000))
    }

    @Test
    fun `undeclared host is not applicable`() {
        assertEquals(Status.UNSUPPORTED, DomainVerificationHelper.statusOf(true, null))
        assertEquals(Status.UNSUPPORTED, DomainVerificationHelper.statusOf(false, null))
    }
}
