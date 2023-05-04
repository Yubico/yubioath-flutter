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

package com.yubico.authenticator.oath.biometrics

import android.content.Context
import android.os.Build
import androidx.biometric.BiometricManager
import com.yubico.authenticator.MainActivity
import com.yubico.authenticator.compatUtil
import com.yubico.authenticator.logging.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class BiometricsMethodChannel(
    context: Context,
    biometricProtection: BiometricProtection,
    messenger: BinaryMessenger
) {

    private val methodChannel = MethodChannel(messenger, "biometrics.methods")

    init {
        methodChannel.setMethodCallHandler { methodCall, result ->
            when (methodCall.method) {
                "hasBiometricsSupport" -> {
                    result.success(
                        compatUtil.from(Build.VERSION_CODES.M) {
                            val biometricManager = BiometricManager.from(context)
                            compatUtil.from(Build.VERSION_CODES.R) {
                                biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG) == BiometricManager.BIOMETRIC_SUCCESS
                            }.otherwise {
                                @Suppress("DEPRECATION")
                                biometricManager.canAuthenticate() == BiometricManager.BIOMETRIC_SUCCESS
                            }
                        }.otherwise {
                            false
                        })
                }

                "setUseBiometrics" -> {
                    biometricProtection.setEnabled(methodCall.arguments as Boolean)
                    result.success(true)
                }

                else -> Log.w(MainActivity.TAG, "Unknown app method: ${methodCall.method}")
            }
        }
    }

    private enum class BiometricsDialogVariant(val value: Int) {
        INVALIDATED(1),
        DISABLED(2);
    }

    fun showBiometricProtectionInvalidatedDialog() {
        methodChannel.invokeMethod(
            "showBiometricsDialog",
            JSONObject(mapOf("variant" to BiometricsDialogVariant.INVALIDATED.value)).toString()
        )
    }

    fun showBiometricProtectionDisabledDialog() {
        methodChannel.invokeMethod(
            "showBiometricsDialog",
            JSONObject(mapOf("variant" to BiometricsDialogVariant.DISABLED.value)).toString()
        )
    }
}