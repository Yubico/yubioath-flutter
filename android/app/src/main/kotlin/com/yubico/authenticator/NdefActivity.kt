/*
 * Copyright (C) 2022-2024 Yubico.
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

import android.annotation.TargetApi
import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.nfc.NdefMessage
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.os.Build
import android.os.Bundle
import android.widget.Toast
import com.yubico.authenticator.ndef.KeyboardLayout
import com.yubico.authenticator.widget.AppWidget
import com.yubico.yubikit.android.transport.nfc.NfcConfiguration
import com.yubico.yubikit.android.transport.nfc.NfcYubiKeyDevice
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.util.NdefUtils
import com.yubico.yubikit.oath.OathSession
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import org.slf4j.LoggerFactory
import java.nio.charset.StandardCharsets
import java.util.Locale
import java.util.Timer
import java.util.concurrent.Executors
import kotlin.concurrent.schedule


typealias ResourceId = Int

class NdefActivity : Activity() {
    private lateinit var appPreferences: AppPreferences

    private val logger = LoggerFactory.getLogger(NdefActivity::class.java)

    companion object {
        private val officialLocalization = arrayOf(Locale.JAPAN, Locale.FRANCE, Locale.US)
    }

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

                    compatUtil.until(Build.VERSION_CODES.TIRAMISU) {
                        showToast(
                            when (otpSlotContent.type) {
                                OtpType.Otp -> R.string.p_ndef_set_otp
                                OtpType.Password -> R.string.p_ndef_set_password
                            }, Toast.LENGTH_SHORT
                        )
                    }

                } catch (illegalArgumentException: IllegalArgumentException) {
                    logger.error(
                        illegalArgumentException.message ?: "Failure when handling YubiKey OTP",
                        illegalArgumentException
                    )
                    showToast(R.string.p_ndef_parse_failure, Toast.LENGTH_LONG)
                } catch (_: UnsupportedOperationException) {
                    showToast(R.string.p_ndef_set_clip_failure, Toast.LENGTH_LONG)
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
            } else {
                updateWidget()
            }

            finishAndRemoveTask()
        }
    }

    data class WidgetContent(
        val issuer: String?,
        val accountName: String,
        val code: String
    )

    private fun updateWidget() {

        // Handle existing tag when launched from NDEF
        val tag = intent.parcelableExtra<Tag>(NfcAdapter.EXTRA_TAG)
        if (tag != null) {
            val nfcConfiguration = NfcConfiguration().timeout(2000)
            intent.removeExtra(NfcAdapter.EXTRA_TAG)

            val executor = Executors.newSingleThreadExecutor()
            val device = NfcYubiKeyDevice(tag, nfcConfiguration.timeout, executor)

            // TODO implement properly
            GlobalScope.launch {
                device.openConnection(SmartCardConnection::class.java).use {
                    val session = OathSession(it)
                    val widgetContent = if (session.credentials.isEmpty()) {
                        null
                    } else {
                        val firstCred = session.credentials[0]
                        val code = session.calculateCode(firstCred)
                        WidgetContent(
                            firstCred.issuer,
                            firstCred.accountName,
                            code.value
                        )
                    }

                    updateWidgetContent(widgetContent)

                    Timer("Clear widget", false).schedule(5 * 1000) {
                        updateWidgetContent(null)
                    }
                }
            }
        }
    }

    private fun updateWidgetContent(widgetContent: WidgetContent?) {
        if (widgetContent != null) {
            AppWidget.hasCode = true
            AppWidget.latestCode = widgetContent.code
            AppWidget.latestIssuer = widgetContent.issuer ?: ""
            AppWidget.latestAccountName = widgetContent.accountName
        } else {
            AppWidget.hasCode = false
        }

        val updateWidgetIntent = Intent(
            this@NdefActivity,
            AppWidget::class.java
        )
        updateWidgetIntent.setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)

        val ids: IntArray = AppWidgetManager.getInstance(application)
            .getAppWidgetIds(
                android.content.ComponentName(
                    application,
                    AppWidget::class.java
                )
            )

        updateWidgetIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        sendBroadcast(updateWidgetIntent)
    }

    private fun showToast(value: ResourceId, length: Int) {
        val context = if (appPreferences.communityTranslationsEnabled)
            this
        else {
            val configuration = resources.configuration
            configuration.setLocale(getLocale())
            createConfigurationContext(configuration)
        }
        Toast.makeText(context, value, length).show()
    }

    private fun getLocale() : Locale =
        compatUtil.from(Build.VERSION_CODES.N) {
            getLocaleN()
        }.otherwise {
            @Suppress("deprecation")
            officialLocalization.firstOrNull {
                it == resources.configuration.locale
            } ?: Locale.US
        }

    @TargetApi(Build.VERSION_CODES.N)
    private fun getLocaleN() : Locale =
        resources.configuration.locales.getFirstMatch(
            officialLocalization.map { it.toLanguageTag() }.toTypedArray()
        ) ?: Locale.US

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
}