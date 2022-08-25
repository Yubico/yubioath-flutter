package com.yubico.authenticator

import android.content.Context
import android.content.SharedPreferences

class AppPreferences(context: Context) {
    companion object {
        const val PREFS_FILE = "FlutterSharedPreferences"
        const val PREF_NFC_OPEN_APP = "flutter.prefNfcOpenApp"
        const val PREF_NFC_BYPASS_TOUCH = "flutter.prefNfcBypassTouch"
        const val PREF_NFC_COPY_OTP = "flutter.prefNfcCopyOtp"

        const val PREF_CLIP_KBD_LAYOUT = "flutter.prefClipKbdLayout"
        const val DEFAULT_CLIP_KBD_LAYOUT = "US"
    }

    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)

    val openAppOnNfcTap: Boolean
        get() = prefs.getBoolean(PREF_NFC_OPEN_APP, true)

    val bypassTouchOnNfcTap: Boolean
        get() = prefs.getBoolean(PREF_NFC_BYPASS_TOUCH, false)

    val copyOtpOnNfcTap: Boolean
        get() = prefs.getBoolean(PREF_NFC_COPY_OTP, false)

    val clipKbdLayout: String
        get() = prefs.getString(
            PREF_CLIP_KBD_LAYOUT,
            DEFAULT_CLIP_KBD_LAYOUT
        )!!
}