package com.yubico.authenticator

import android.app.Activity
import android.content.*
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.widget.Toast

import com.yubico.authenticator.Constants.Companion.EXTRA_OPENED_THROUGH_NFC

import com.yubico.authenticator.logging.Log

typealias ResourceId = Int

class YOTPActivity : Activity() {

    private var openAppOnNfcTap: Boolean = false
    private var copyOtpOnNfcTap: Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val prefs: SharedPreferences = getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
        openAppOnNfcTap = prefs.getBoolean(PREF_NFC_OPEN_APP, false)
        copyOtpOnNfcTap = prefs.getBoolean(PREF_NFC_COPY_OTP, false)

        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    override fun onPause() {
        super.onPause()
        overridePendingTransition(0, 0)
    }

    private fun handleIntent(intent: Intent) {
        intent.data?.let { uri ->

            if (copyOtpOnNfcTap) {
                try {
                    val otp = parseOtpFromUri(uri)
                    setPrimaryClip(otp)

                    if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.S_V2) {
                        showToast(R.string.otp_success, Toast.LENGTH_SHORT)
                    }
                } catch (_: IllegalArgumentException) {
                    showToast(R.string.otp_parse_failure, Toast.LENGTH_LONG)
                } catch (_: UnsupportedOperationException) {
                    showToast(R.string.otp_set_clip_failure, Toast.LENGTH_LONG)
                }

            }

            if (openAppOnNfcTap) {
                val mainAppIntent = Intent(this, MainActivity::class.java).apply {
                    putExtra(EXTRA_OPENED_THROUGH_NFC, true)
                }
                startActivity(mainAppIntent)
            }

            finishAndRemoveTask()
        }
    }

    private fun showToast(value: ResourceId, length: Int) {
        Toast.makeText(this, value, length).show()
    }

    private fun parseOtpFromUri(uri: Uri): String {
        uri.fragment?.let {
            if (it.length == 44) {
                return it
            }
        }

        Log.e(TAG, "Failed to parse OTP from provided otp uri string")
        Log.t(TAG, "Uri was $uri")
        throw IllegalArgumentException()
    }

    private fun setPrimaryClip(otp: String) {
        try {
            val clipboardManager = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            clipboardManager.setPrimaryClip(ClipData.newPlainText(otp, otp))
        } catch (e: Exception) {
            Log.e(TAG, "Failed to copy otp string to clipboard", e.stackTraceToString())
            throw UnsupportedOperationException()
        }
    }

    companion object {
        const val TAG = "YubicoAuthenticatorOTPActivity"
        const val PREFS_FILE = "FlutterSharedPreferences"
        const val PREF_NFC_OPEN_APP = "flutter.prefNfcOpenApp"
        const val PREF_NFC_COPY_OTP = "flutter.prefNfcCopyOtp"
    }

}