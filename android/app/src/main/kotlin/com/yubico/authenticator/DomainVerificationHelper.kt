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

import android.content.Context
import android.content.Intent
import android.content.pm.verify.domain.DomainVerificationManager
import android.content.pm.verify.domain.DomainVerificationUserState
import android.net.Uri
import android.os.Build
import android.provider.Settings
import org.slf4j.LoggerFactory

/**
 * Helper for inspecting and managing the system-level "Open by default" status
 * of the my.yubico.com domain.
 *
 * On Android 16 (API 36), NFC taps on a YubiKey no longer broadcast
 * NDEF_DISCOVERED but launch the my.yubico.com URL via ACTION_VIEW. The app is
 * registered to handle that URL but, unless Digital Asset Links auto-verifies
 * the association or the user manually opted in via Settings → Apps → Yubico
 * Authenticator → Open by default, ACTION_VIEW falls back to a browser. This
 * helper lets the app detect that situation and deep-link the user to the
 * relevant settings page.
 *
 * The DomainVerificationManager API is available from Android 12 (API 31), but
 * the underlying problem only exists on Android 16+: on earlier releases NFC
 * taps still arrive via NDEF_DISCOVERED regardless of link verification state.
 * Therefore [getStatus] returns [STATUS_UNSUPPORTED] below API 36 to avoid
 * nagging users on OS versions that aren't affected.
 */
object DomainVerificationHelper {
    private const val YUBICO_HOST = "my.yubico.com"

    // Android 16 / Baklava. Hardcoded so this compiles regardless of which
    // version constants are present in the configured compileSdk.
    private const val ANDROID_16 = 36

    /** API not available, or running on an OS version unaffected by the issue. */
    const val STATUS_UNSUPPORTED = "unsupported"

    /** Domain is auto-verified via Digital Asset Links — no action needed. */
    const val STATUS_VERIFIED = "verified"

    /** User has explicitly opted the app in for the domain — no action needed. */
    const val STATUS_SELECTED = "selected"

    /** No association — ACTION_VIEW will fall back to a browser. */
    const val STATUS_NONE = "none"

    private val logger = LoggerFactory.getLogger(DomainVerificationHelper::class.java)

    fun getStatus(context: Context): String {
        // Only Android 16 routes NFC YubiKey taps through ACTION_VIEW; older
        // releases still deliver NDEF_DISCOVERED, so the association state
        // is irrelevant for tap-to-launch there.
        if (Build.VERSION.SDK_INT < ANDROID_16) {
            return STATUS_UNSUPPORTED
        }
        return try {
            val manager = context.getSystemService(DomainVerificationManager::class.java)
                ?: return STATUS_UNSUPPORTED
            val userState = manager.getDomainVerificationUserState(context.packageName)
                ?: return STATUS_UNSUPPORTED
            // If the user disabled "Open supported links" globally for the
            // app, ACTION_VIEW won't be routed here even when individual
            // hosts are verified or selected. Treat that as not associated.
            if (!userState.isLinkHandlingAllowed) {
                return STATUS_NONE
            }
            when (userState.hostToStateMap[YUBICO_HOST]) {
                DomainVerificationUserState.DOMAIN_STATE_VERIFIED -> STATUS_VERIFIED
                DomainVerificationUserState.DOMAIN_STATE_SELECTED -> STATUS_SELECTED
                DomainVerificationUserState.DOMAIN_STATE_NONE -> STATUS_NONE
                // Host not registered for this app.
                null -> STATUS_UNSUPPORTED
                else -> STATUS_NONE
            }
        } catch (e: Exception) {
            logger.warn("Failed to query domain verification state", e)
            STATUS_UNSUPPORTED
        }
    }

    /**
     * Opens the system "Open by default" page for this app. Available from
     * Android 12 (API 31), but only invoked from the Android 16+ flow.
     * Returns true if a settings activity was started.
     */
    fun openSettings(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return false
        }
        val uri = Uri.fromParts("package", context.packageName, null)
        val flags = Intent.FLAG_ACTIVITY_NEW_TASK
        // ACTION_APP_OPEN_BY_DEFAULT_SETTINGS deep-links to the per-app
        // "Open by default" page on Android 12+, where the user can toggle
        // "Open supported links" and review my.yubico.com.
        val direct = Intent(Settings.ACTION_APP_OPEN_BY_DEFAULT_SETTINGS, uri)
            .addFlags(flags)
        if (direct.resolveActivity(context.packageManager) != null) {
            context.startActivity(direct)
            return true
        }
        val fallback = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, uri)
            .addFlags(flags)
        if (fallback.resolveActivity(context.packageManager) != null) {
            context.startActivity(fallback)
            return true
        }
        logger.warn("No settings activity available for domain verification")
        return false
    }
}
