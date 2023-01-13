/*
 * Copyright (C) 2022 Yubico.
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
import android.content.SharedPreferences
import android.content.SharedPreferences.OnSharedPreferenceChangeListener
import com.yubico.authenticator.logging.Log

class AppPreferences(context: Context) {
    companion object {
        const val PREFS_FILE = "FlutterSharedPreferences"
        const val PREF_NFC_OPEN_APP = "flutter.prefNfcOpenApp"
        const val PREF_NFC_BYPASS_TOUCH = "flutter.prefNfcBypassTouch"
        const val PREF_NFC_SILENCE_SOUNDS = "flutter.prefNfcSilenceSounds"
        const val PREF_NFC_COPY_OTP = "flutter.prefNfcCopyOtp"
        const val PREF_USB_OPEN_APP = "flutter.prefUsbOpenApp"

        const val PREF_CLIP_KBD_LAYOUT = "flutter.prefClipKbdLayout"
        const val DEFAULT_CLIP_KBD_LAYOUT = "US"

        const val TAG = "AppPreferences"
    }

    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE).also {
            Log.d(TAG, "Current app preferences:")
            it.all.map { preference ->
                Log.d(TAG, "${preference.key}: ${preference.value}")
            }
        }

    val openAppOnNfcTap: Boolean
        get() = prefs.getBoolean(PREF_NFC_OPEN_APP, true)

    val bypassTouchOnNfcTap: Boolean
        get() = prefs.getBoolean(PREF_NFC_BYPASS_TOUCH, false)

    val silenceNfcSounds: Boolean
        get() = prefs.getBoolean(PREF_NFC_SILENCE_SOUNDS, false)

    val copyOtpOnNfcTap: Boolean
        get() = prefs.getBoolean(PREF_NFC_COPY_OTP, false)

    val clipKbdLayout: String
        get() = prefs.getString(
            PREF_CLIP_KBD_LAYOUT,
            DEFAULT_CLIP_KBD_LAYOUT
        )!!

    val openAppOnUsb: Boolean
        get() = prefs.getBoolean(PREF_USB_OPEN_APP, false)

    fun registerListener(listener: OnSharedPreferenceChangeListener) {
        Log.d(TAG, "registering change listener")
        prefs.registerOnSharedPreferenceChangeListener(listener)
    }

    fun unregisterListener(listener: OnSharedPreferenceChangeListener) {
        prefs.unregisterOnSharedPreferenceChangeListener(listener)
        Log.d(TAG, "unregistered change listener")
    }
}