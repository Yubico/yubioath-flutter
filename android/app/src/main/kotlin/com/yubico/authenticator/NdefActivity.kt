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

import android.app.Activity
import android.content.Intent
import android.nfc.NdefMessage
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.os.Build
import android.os.Bundle
import android.widget.Toast
import com.yubico.authenticator.logging.Log
import com.yubico.authenticator.ndef.KeyboardLayout
import com.yubico.yubikit.core.util.NdefUtils
import java.nio.charset.StandardCharsets

typealias ResourceId = Int

class NdefActivity : Activity() {
    private lateinit var appPreferences: AppPreferences

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        appPreferences = AppPreferences(this)
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
        intent.data?.let {
            if (appPreferences.copyOtpOnNfcTap) {
                try {
                    val otpSlotContent = parseOtpFromIntent()
                    ClipboardUtil.setPrimaryClip(this, otpSlotContent.content, true)

                    if (SdkVersion.lt(Build.VERSION_CODES.TIRAMISU)) {
                        showToast(
                            when (otpSlotContent.type) {
                                OtpType.Otp -> R.string.otp_success_set_otp_to_clipboard
                                OtpType.Password -> R.string.otp_success_set_password_to_clipboard
                            }, Toast.LENGTH_SHORT
                        )
                    }

                } catch (illegalArgumentException: IllegalArgumentException) {
                    Log.e(
                        TAG,
                        illegalArgumentException.message ?: "Failure when handling YubiKey OTP",
                        illegalArgumentException.stackTraceToString()
                    )
                    showToast(R.string.otp_parse_failure, Toast.LENGTH_LONG)
                } catch (_: UnsupportedOperationException) {
                    showToast(R.string.otp_set_clip_failure, Toast.LENGTH_LONG)
                }
            }

            if (appPreferences.openAppOnNfcTap) {
                val mainAppIntent = Intent(this, MainActivity::class.java).apply {
                    // Pass the NFC Tag to the main Activity.
                    putExtra(NfcAdapter.EXTRA_TAG, intent.parcelableExtra<Tag>(NfcAdapter.EXTRA_TAG))
                }
                startActivity(mainAppIntent)
            }

            finishAndRemoveTask()
        }
    }

    private fun showToast(value: ResourceId, length: Int) {
        Toast.makeText(this, value, length).show()
    }

    private fun parseOtpFromIntent(): OtpSlotValue {
        val parcelable = intent.parcelableArrayExtra<NdefMessage>(NfcAdapter.EXTRA_NDEF_MESSAGES)
        requireNotNull(parcelable) { "Null NDEF message" }
        require(parcelable.isNotEmpty()) { "Empty NDEF message" }

        val ndefPayloadBytes =
            NdefUtils.getNdefPayloadBytes((parcelable[0]).toByteArray())

        return if (ndefPayloadBytes.all { it in 32..126 }) {
            OtpSlotValue(OtpType.Otp, String(ndefPayloadBytes, StandardCharsets.US_ASCII))
        } else {
            val kbd: KeyboardLayout = KeyboardLayout.forName(appPreferences.clipKbdLayout)
            OtpSlotValue(OtpType.Password, kbd.fromScanCodes(ndefPayloadBytes))
        }
    }

    companion object {
        const val TAG = "YubicoAuthenticatorOTPActivity"
    }

    enum class OtpType {
        Otp, Password
    }

    data class OtpSlotValue(val type: OtpType, val content: String)
}