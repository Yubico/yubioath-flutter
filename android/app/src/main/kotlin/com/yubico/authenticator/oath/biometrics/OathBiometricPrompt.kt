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

import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import androidx.lifecycle.lifecycleScope
import com.yubico.authenticator.R
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.concurrent.Executor

data class AuthenticationCallbacks(
    val onAuthenticationError: ((Int, CharSequence) -> Unit)? = null,
    val onAuthenticationSucceeded: ((BiometricPrompt.AuthenticationResult) -> Unit)? = null,
    val onAuthenticationFailed: (() -> Unit)? = null
)

class AuthenticationCallback(
    var authenticationCallbacks: AuthenticationCallbacks
) : BiometricPrompt.AuthenticationCallback() {

    override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
        super.onAuthenticationError(errorCode, errString)
        authenticationCallbacks.onAuthenticationError?.invoke(errorCode, errString)
    }

    override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
        super.onAuthenticationSucceeded(result)
        authenticationCallbacks.onAuthenticationSucceeded?.invoke(result)
    }

    override fun onAuthenticationFailed() {
        super.onAuthenticationFailed()
        authenticationCallbacks.onAuthenticationFailed?.invoke()
    }
}

class OathBiometricPrompt(private val fragmentActivity: FragmentActivity) {

    private var executor: Executor = ContextCompat.getMainExecutor(fragmentActivity)
    private var biometricPrompt: BiometricPrompt
    private var promptInfo: BiometricPrompt.PromptInfo
    private val authenticationCallback =
        AuthenticationCallback(AuthenticationCallbacks())

    init {
        biometricPrompt = BiometricPrompt(fragmentActivity, executor, authenticationCallback)

        promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle(fragmentActivity.getString(R.string.oath_biometric_prompt_title))
            .setNegativeButtonText(fragmentActivity.getString(R.string.oath_biometric_prompt_negative_button))
            .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
            .build()
    }

    fun authenticate(
        authenticationCallbacks: AuthenticationCallbacks,
        cryptoObject: BiometricPrompt.CryptoObject? = null,
    ) {
        fragmentActivity.lifecycleScope.launch(Dispatchers.Main) {
            authenticationCallback.authenticationCallbacks = authenticationCallbacks
            if (cryptoObject != null) {
                biometricPrompt.authenticate(promptInfo, cryptoObject)
            } else {
                biometricPrompt.authenticate(promptInfo)
            }
        }
    }

}