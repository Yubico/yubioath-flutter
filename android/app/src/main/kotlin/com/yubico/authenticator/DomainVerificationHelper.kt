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

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.verify.domain.DomainVerificationManager
import android.content.pm.verify.domain.DomainVerificationUserState
import android.net.Uri
import android.os.Build
import android.provider.Settings
import org.slf4j.LoggerFactory

/**
 * Reports whether this app is the system's handler for `https://my.yubico.com` links, and opens
 * the settings page where the user can make it one.
 *
 * From Android 16, an NFC tap with a YubiKey reaches the app as a web link for my.yubico.com
 * rather than through `NDEF_DISCOVERED`, so every NFC tap action (launch, copy, or both)
 * depends on the app owning that domain. Builds signed with Yubico's release key get it
 * automatically through Digital Asset Links (`https://my.yubico.com/.well-known/assetlinks.json`
 * lists that certificate for `com.yubico.yubioath`). Any other build (a self-build, a
 * rebuild signed by a third party, or a `.debug` build with its different package name) fails
 * verification, and the user has to add the domain by hand under *Open by default*.
 */
object DomainVerificationHelper {
    const val HOST = "my.yubico.com"

    /** Wire values sent over the `app.methods` channel; mirrored by `DomainVerificationStatus` in Dart. */
    enum class Status(val value: String) {
        /** Not applicable: Android older than 16, the API is unavailable, or the host isn't declared. */
        UNSUPPORTED("unsupported"),

        /** Verified through Digital Asset Links. */
        VERIFIED("verified"),

        /** The user added the domain under *Open by default*. */
        SELECTED("selected"),

        /** The app does not handle my.yubico.com links, so NFC tap actions do nothing. */
        NONE("none")
    }

    private val logger = LoggerFactory.getLogger(DomainVerificationHelper::class.java)

    fun getStatus(context: Context): Status {
        // Below Android 16 the tap still arrives as NDEF_DISCOVERED, which does not depend on
        // link verification.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.BAKLAVA) {
            return Status.UNSUPPORTED
        }
        return try {
            val userState = context.getSystemService(DomainVerificationManager::class.java)
                ?.getDomainVerificationUserState(context.packageName)
                ?: return Status.UNSUPPORTED
            statusOf(userState.isLinkHandlingAllowed, userState.hostToStateMap[HOST])
        } catch (e: Exception) {
            logger.warn("Failed to query domain verification state", e)
            Status.UNSUPPORTED
        }
    }

    /**
     * Maps the system's per-app link state to a [Status].
     *
     * @param linkHandlingAllowed [DomainVerificationUserState.isLinkHandlingAllowed]: false when
     * the user turned off *Open supported links*, which overrides every per-host state.
     * @param hostState the [HOST] entry of [DomainVerificationUserState.getHostToStateMap], or
     * null if the manifest does not declare the host.
     */
    internal fun statusOf(linkHandlingAllowed: Boolean, hostState: Int?): Status = when {
        hostState == null -> Status.UNSUPPORTED
        !linkHandlingAllowed -> Status.NONE
        hostState == DomainVerificationUserState.DOMAIN_STATE_VERIFIED -> Status.VERIFIED
        hostState == DomainVerificationUserState.DOMAIN_STATE_SELECTED -> Status.SELECTED
        else -> Status.NONE
    }

    /**
     * Opens the app's *Open by default* page, falling back to its app info page. Returns true if
     * a settings screen was started.
     *
     * Starts the intent and catches the failure instead of checking `resolveActivity` first:
     * under package visibility rules `resolveActivity` can return null for a settings screen
     * that exists.
     */
    fun openSettings(activity: Activity): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            return false
        }
        val uri = Uri.fromParts("package", activity.packageName, null)
        return listOf(
            Settings.ACTION_APP_OPEN_BY_DEFAULT_SETTINGS,
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS
        ).any { action ->
            try {
                activity.startActivity(Intent(action, uri))
                true
            } catch (e: ActivityNotFoundException) {
                logger.warn("No activity for {}", action, e)
                false
            }
        }
    }
}
