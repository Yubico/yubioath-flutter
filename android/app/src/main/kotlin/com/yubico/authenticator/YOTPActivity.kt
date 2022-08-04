package com.yubico.authenticator

import android.app.Activity
import android.content.*
import android.net.Uri
import android.nfc.NdefMessage
import android.nfc.NfcAdapter
import android.os.Build
import android.os.Bundle
import android.widget.Toast
import com.yubico.authenticator.Constants.Companion.EXTRA_OPENED_THROUGH_NFC
import com.yubico.authenticator.logging.Log
import com.yubico.authenticator.yubiclip.scancode.KeyboardLayout
import java.util.*
import java.util.regex.Pattern

typealias ResourceId = Int

class YOTPActivity : Activity() {

    private val otpPattern = Pattern.compile(".*/#?([a-zA-Z0-9!]+)$")

    private var openAppOnNfcTap: Boolean = false
    private var copyOtpOnNfcTap: Boolean = false
    private lateinit var clipKbdLayout: String

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val prefs: SharedPreferences = getSharedPreferences(PREFS_FILE, Context.MODE_PRIVATE)
        openAppOnNfcTap = prefs.getBoolean(PREF_NFC_OPEN_APP, false)
        copyOtpOnNfcTap = prefs.getBoolean(PREF_NFC_COPY_OTP, false)
        clipKbdLayout = prefs.getString(PREF_CLIP_KBD_LAYOUT, DEFAULT_CLIP_KBD_LAYOUT)!!

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

        val matcher = otpPattern.matcher(uri.toString())
        if (matcher.matches()) {
            matcher.group(1)?.let {
                return it
            }
        }

        val fromNdefMessages = parseExtraNdefMessages()
        if (fromNdefMessages != null) {
            return fromNdefMessages
        }

        Log.e(TAG, "Failed to parse OTP from provided otp uri string")
        Log.t(TAG, "Uri was $uri")
        throw IllegalArgumentException()
    }

    private fun parseExtraNdefMessages(): String? {
        val prefix = "https://my.yubico.com/"
        val ndefRecord = 0xd1.toByte()
        val prefixByteArr = ByteArray(prefix.length + 2 - 8)

        try {
            prefixByteArr[0] = 85
            prefixByteArr[1] = 4
            System.arraycopy(
                prefix.substring(8).toByteArray(),
                0,
                prefixByteArr,
                2,
                prefixByteArr.size - 2
            )

            // get intent extra if possible
            val raw = intent.getParcelableArrayExtra(NfcAdapter.EXTRA_NDEF_MESSAGES)
            var bytes = (raw!![0] as NdefMessage).toByteArray()
            if (bytes[0] == ndefRecord && Arrays.equals(
                    prefixByteArr,
                    Arrays.copyOfRange(bytes, 3, 3 + prefixByteArr.size)
                )
            ) {
                if (Arrays.equals("/neo/".toByteArray(), Arrays.copyOfRange(bytes, 18, 18 + 5))) {
                    bytes[22] = '#'.code.toByte()
                }
                for (i in bytes.indices) {
                    if (bytes[i] == '#'.code.toByte()) {
                        bytes = Arrays.copyOfRange(bytes, i + 1, bytes.size)
                        val kbd: KeyboardLayout = KeyboardLayout.forName(clipKbdLayout)
                        return kbd.fromScanCodes(bytes)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse NDEF messages", e.stackTraceToString())
            throw IllegalArgumentException()
        }

        return null
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

        const val PREF_CLIP_KBD_LAYOUT = "flutter.prefClipKbdLayout"
        const val DEFAULT_CLIP_KBD_LAYOUT = "US"
    }

}