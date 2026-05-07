/*
 * Copyright (C) 2023-2026 Yubico.
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
import android.content.ComponentName
import android.content.pm.PackageManager
import org.slf4j.LoggerFactory

class ActivityUtil(private val activity: Activity) {

    private val logger = LoggerFactory.getLogger(ActivityUtil::class.java)

    /**
     * The app will be started when a complaint USB device is attached.
     *
     * Calling this method will enable <code>AliasMainActivity</code> alias which contains
     * intent-filter for android.hardware.usb.action.USB_DEVICE_ATTACHED. This alias is disabled by
     * default in the AndroidManifest.xml.
     *
     * Devices which will activate the intent filter are defined in `res/xml/device_filter.xml`.
     * @see <a href="https://developer.android.com/guide/topics/manifest/activity-alias-element">Activity Alias in Android SDK documentation</a>
     */
    fun enableSystemUsbDiscovery() {
        setState(
            MAIN_ACTIVITY_ALIAS,
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED
        )
        logger.debug("Enabled USB discovery by setting state of $MAIN_ACTIVITY_ALIAS to ENABLED")
    }

    /**
     * The system will not start this app when a complaint USB device is attached.
     *
     * Calling this method will disable <code>AliasMainActivity</code> alias and the intent-filter
     * for android.hardware.usb.action.USB_DEVICE_ATTACHED will not be active.
     *
     * @see <a href="https://developer.android.com/guide/topics/manifest/activity-alias-element">Activity Alias in Android SDK documentation</a>
     */
    fun disableSystemUsbDiscovery() {
        setState(
            MAIN_ACTIVITY_ALIAS,
            PackageManager.COMPONENT_ENABLED_STATE_DEFAULT
        )
        logger.debug("Disabled USB discovery by setting state of $MAIN_ACTIVITY_ALIAS to DEFAULT")
    }

    /**
     * The system will start the app when an NDEF tag with recognized URI is discovered.
     *
     * Calling this method will enable both <code>AliasNdefActivity</code> (handling
     * android.nfc.action.NDEF_DISCOVERED on Android 15 and below, and as a fallback on builds
     * whose App Links cannot be verified) and <code>AliasNdefAppLinkActivity</code> (handling
     * the Android 16+ android.intent.action.VIEW dispatch for verified App Links). This is the
     * default behavior as defined in the AndroidManifest.xml.
     *
     * For list of discoverable URIs see the alias definitions in AndroidManifest.xml.
     *
     * @see <a href="https://developer.android.com/guide/topics/manifest/activity-alias-element">Activity Alias in Android SDK documentation</a>
     */
    fun enableAppNfcDiscovery() {
        setState(NDEF_ACTIVITY_ALIAS, PackageManager.COMPONENT_ENABLED_STATE_DEFAULT)
        setState(NDEF_APP_LINK_ACTIVITY_ALIAS, PackageManager.COMPONENT_ENABLED_STATE_DEFAULT)
        logger.debug(
            "Enabled NFC discovery by setting state of $NDEF_ACTIVITY_ALIAS and $NDEF_APP_LINK_ACTIVITY_ALIAS to DEFAULT"
        )
    }

    /**
     * The system will ignore the app when NDEF tags are discovered.
     *
     * Calling this method will disable both <code>AliasNdefActivity</code> and
     * <code>AliasNdefAppLinkActivity</code>, removing them from the system NFC resolver so the
     * app is neither offered as a handler nor launched on tap. <code>DISABLED</code> (rather
     * than <code>DEFAULT</code>) is required because the manifest declares both aliases as
     * <code>android:enabled="true"</code>; <code>DEFAULT</code> would leave them visible in the
     * NFC chooser.
     *
     * @see <a href="https://developer.android.com/guide/topics/manifest/activity-alias-element">Activity Alias in Android SDK documentation</a>
     */
    fun disableAppNfcDiscovery() {
        setState(NDEF_ACTIVITY_ALIAS, PackageManager.COMPONENT_ENABLED_STATE_DISABLED)
        setState(NDEF_APP_LINK_ACTIVITY_ALIAS, PackageManager.COMPONENT_ENABLED_STATE_DISABLED)
        logger.debug(
            "Disabled NFC discovery by setting state of $NDEF_ACTIVITY_ALIAS and $NDEF_APP_LINK_ACTIVITY_ALIAS to DISABLED"
        )
    }

    private fun setState(aliasName: String, enabledState: Int) {
        val componentName =
            ComponentName(activity.packageName, "com.yubico.authenticator.$aliasName")
        activity.applicationContext.packageManager.setComponentEnabledSetting(
            componentName,
            enabledState,
            PackageManager.DONT_KILL_APP
        )
        logger.trace("Activity alias '$aliasName' is enabled: $enabledState")
    }

    companion object {
        const val NDEF_ACTIVITY_ALIAS = "AliasNdefActivity"
        const val NDEF_APP_LINK_ACTIVITY_ALIAS = "AliasNdefAppLinkActivity"
        const val MAIN_ACTIVITY_ALIAS = "AliasMainActivity"
    }
}
