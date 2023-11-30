/*
 * Copyright (C) 2022-2023 Yubico.
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
import android.nfc.NdefMessage
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.os.Build
import android.os.Bundle
import android.widget.Toast
import com.yubico.authenticator.app.AppMethodChannel
import com.yubico.authenticator.logging.FlutterLog
import com.yubico.authenticator.ndef.KeyboardLayout
import com.yubico.yubikit.core.util.NdefUtils
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.slf4j.LoggerFactory
import java.nio.charset.StandardCharsets

class NdefActivity : FlutterFragmentActivity() {
    private val coroutineScope = CoroutineScope(Dispatchers.Main)

    private lateinit var appPreferences: AppPreferences
    private lateinit var appMethodChannel: AppMethodChannel
    private lateinit var flutterLog: FlutterLog

    private val logger = LoggerFactory.getLogger(NdefActivity::class.java)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        appPreferences = AppPreferences(this)

    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        coroutineScope.launch {
            handleIntent(intent)
        }
    }

    override fun onPause() {
        super.onPause()
        overridePendingTransition(0, 0)
    }

    private suspend fun handleIntent(intent: Intent) {
        intent.data?.let {
            if (appPreferences.copyOtpOnNfcTap) {
                try {
                    val otpSlotContent = parseOtpFromIntent()
                    ClipboardUtil.setPrimaryClip(this, otpSlotContent.content, true)

                    compatUtil.until(Build.VERSION_CODES.TIRAMISU, block = suspend {
                        showToast(
                            this,
                            when (otpSlotContent.type) {
                                OtpType.Otp -> "p_ndef_set_otp"
                                OtpType.Password -> "p_ndef_set_password"
                            }, Toast.LENGTH_SHORT
                        )
                    }
                    )

                } catch (illegalArgumentException: IllegalArgumentException) {
                    logger.error(
                        illegalArgumentException.message ?: "Failure when handling YubiKey OTP",
                        illegalArgumentException
                    )
                    showToast(this, "p_ndef_parse_failure", Toast.LENGTH_LONG)
                } catch (_: UnsupportedOperationException) {
                    showToast(this, "p_ndef_set_clip_failure", Toast.LENGTH_LONG)
                }
            }

            if (appPreferences.openAppOnNfcTap) {
                val mainAppIntent = Intent(this, MainActivity::class.java).apply {
                    // Pass the NFC Tag to the main Activity.
                    putExtra(
                        NfcAdapter.EXTRA_TAG,
                        intent.parcelableExtra<Tag>(NfcAdapter.EXTRA_TAG)
                    )
                }
                startActivity(mainAppIntent)
            }

            finishAndRemoveTask()
        }
    }


    private suspend fun showToast(context: Context, arbKey: String, length: Int) {
        Toast.makeText(context, appMethodChannel.getString(arbKey), length).show()
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

    enum class OtpType {
        Otp, Password
    }

    data class OtpSlotValue(val type: OtpType, val content: String)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        appMethodChannel = AppMethodChannel(this, messenger)
        flutterLog = FlutterLog(messenger)

        coroutineScope.launch {
            handleIntent(intent)
        }
    }
}