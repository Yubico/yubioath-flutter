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
    }

    /**
     * The system will start the app when an NDEF tag with recognized URI is discovered.
     *
     * Calling this method will enable <code>AliasNdefActivity</code> alias and the intent-filter
     * for android.nfc.action.NDEF_DISCOVERED will be active. This is the default behavior as
     * defined in the AndroidManifest.xml.
     *
     * For list of discoverable URIs see the alias definition in AndroidManifest.xml.
     *
     * @see <a href="https://developer.android.com/guide/topics/manifest/activity-alias-element">Activity Alias in Android SDK documentation</a>
     */
    fun enableAppNfcDiscovery() {
        setState(
            NDEF_ACTIVITY_ALIAS,
            PackageManager.COMPONENT_ENABLED_STATE_DEFAULT
        )
    }

    /**
     * The system will ignore the app when NDEF tags are discovered.
     *
     * Calling this method will disable <code>AliasNdefActivity</code> alias and there will be no
     * active intent-filter for android.nfc.action.NDEF_DISCOVERED.
     *
     * @see <a href="https://developer.android.com/guide/topics/manifest/activity-alias-element">Activity Alias in Android SDK documentation</a>
     */
    fun disableAppNfcDiscovery() {
        setState(
            NDEF_ACTIVITY_ALIAS,
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED
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
        const val MAIN_ACTIVITY_ALIAS = "AliasMainActivity"
    }

}