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

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import android.security.keystore.UserNotAuthenticatedException
import androidx.annotation.RequiresApi
import androidx.biometric.BiometricManager
import androidx.fragment.app.FragmentActivity
import com.yubico.authenticator.AppPreferences
import com.yubico.authenticator.compatUtil
import com.yubico.authenticator.logging.Log
import com.yubico.authenticator.oath.keystore.getAlias
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature
import java.security.SignatureException
import java.security.spec.ECGenParameterSpec

open class BiometricProtection {

    enum class UserAuthenticationStatus {
        KEY_PERMANENTLY_INVALIDATED,
        USER_NOT_AUTHENTICATED,
        CANT_AUTHENTICATE,
        SUCCESS
    }

    open fun canAuthenticate() = false

    open fun getAuthenticationStatus(deviceId: String): UserAuthenticationStatus =
        UserAuthenticationStatus.SUCCESS

    open fun setEnabled(enabled: Boolean) {}

    open fun authenticate(
        deviceId: String,
        onError: (error: Int, errorMessage: String) -> Unit,
        onKeyInvalidated: () -> Unit,
        onCancelOrFail: () -> Unit,
        onSuccess: () -> Unit
    ) {}
}

@RequiresApi(Build.VERSION_CODES.M)
class BiometricProtectionSinceM(
    activity: FragmentActivity,
    private val appPreferences: AppPreferences
) : BiometricProtection() {

    private val applicationContext = activity.applicationContext

    override fun canAuthenticate(): Boolean = compatUtil.from(Build.VERSION_CODES.M) {
        val biometricManager = BiometricManager.from(applicationContext)
        compatUtil.from(Build.VERSION_CODES.R) {
            biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG) == BiometricManager.BIOMETRIC_SUCCESS
        }.otherwise {
            @Suppress("DEPRECATION")
            biometricManager.canAuthenticate() == BiometricManager.BIOMETRIC_SUCCESS
        }
    }.otherwise {
        false
    }

    override fun getAuthenticationStatus(deviceId: String): UserAuthenticationStatus {

        // user is authenticated if the use of biometrics is turned off
        if (!appPreferences.useBiometrics) {
            Log.d(TAG, "Not using biometrics")
            return UserAuthenticationStatus.SUCCESS
        }

        if (appPreferences.useBiometrics && !canAuthenticate()) {
            Log.d(TAG, "Wants to use biometrics, but system does not support it")
            return UserAuthenticationStatus.CANT_AUTHENTICATE
        }

        if (!keystore.containsAlias(getAlias(deviceId))) {
            // the deviceId does not have it's access key secret in the keystore
            // we don't need to verify user authentication
            Log.d(TAG, "Access key for $deviceId is not remembered")
            return UserAuthenticationStatus.SUCCESS
        }

        val authKey = getKey()
        if (authKey == null) {
            Log.d(TAG, "Could not find auth key for biometric authentication")
            return UserAuthenticationStatus.KEY_PERMANENTLY_INVALIDATED
        }

        return verifyAuthentication(authKey)
    }

    override fun authenticate(
        deviceId: String,
        onError: (error: Int, errorMessage: String) -> Unit,
        onKeyInvalidated: () -> Unit,
        onCancelOrFail: () -> Unit,
        onSuccess: () -> Unit
    ) {
        biometricPrompt.authenticate(AuthenticationCallbacks(
            onAuthenticationError = { err, errorMessage ->
                // there is a problem with the biometric authentication system
                // for example it was disabled, or there are no fingerprints or faces enrolled;
                // or there is a HW failure or the system requires update
                // for Yubico Authenticator this means that we have to disable the Biometric Protection
                Log.e(TAG, "Biometric authentication error $err: $errorMessage")
                onError(err, errorMessage.toString())
            },
            onAuthenticationSucceeded = {
                Log.d(TAG, "Biometric authentication succeeded, verifying authentication key")

                val authKey = getKey()
                if (authKey == null) {
                    onError(BiometricManager.BIOMETRIC_STATUS_UNKNOWN, "Authentication Key does not exists in KeyStore").also {
                        Log.e(TAG, "Failed to find authentication key")
                    }
                    return@AuthenticationCallbacks
                }

                when (verifyAuthentication(authKey)) {
                    UserAuthenticationStatus.SUCCESS -> onSuccess().also {
                        Log.d(TAG, "User is now verified by biometrics")
                    }

                    // explanation for why both statuses trigger onKeyPermanentlyInvalidated:
                    // we are in onAuthenticationSucceeded callback of BiometricPrompt which means,
                    // that if the key is still not authenticated, the key is not valid anymore
                    UserAuthenticationStatus.KEY_PERMANENTLY_INVALIDATED,
                    UserAuthenticationStatus.USER_NOT_AUTHENTICATED -> onKeyInvalidated().also {
                        Log.e(TAG, "The private key is not valid for signatures anymore")
                    }

                    UserAuthenticationStatus.CANT_AUTHENTICATE -> onError(
                        BiometricManager.BIOMETRIC_ERROR_UNSUPPORTED,
                        "Device cannot use biometric authentication"
                    ).also {
                        Log.e(TAG, "Device cannot use biometric authentication")
                    }
                }
            },
            onAuthenticationFailed = {
                Log.e(
                    TAG,
                    "Error authenticating user, the biometric information does not match!"
                )
                onCancelOrFail()
            }
        ))
    }

    override fun setEnabled(enabled: Boolean) {

        if (!enabled) {
            Log.d(TAG, "Disabling biometric protection")
            // remove all information from key store
            keystore.aliases().asSequence().forEach { keystore.deleteEntry(it) }
            appPreferences.setUseBiometrics(false)
        } else {
            Log.d(TAG, "Enabling biometric protection")
            if (getKey() == null) {
                Log.d(TAG, "$KEY_ALIAS not present in keystore, creating")
                generateECKey()
            } else {
                Log.d(TAG, "$KEY_ALIAS was found in keystore, reusing")
            }
        }
    }

    private val biometricPrompt = OathBiometricPrompt(activity)

    private val keystore = KeyStore.getInstance("AndroidKeyStore").also {
        it.load(null)
    }

    private fun generateECKey() {
        val timeout = 15

        val specBuilder = KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_SIGN
        )
            .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setUserAuthenticationRequired(true)

        compatUtil.from(Build.VERSION_CODES.R) {
            specBuilder.setUserAuthenticationParameters(
                timeout,
                KeyProperties.AUTH_BIOMETRIC_STRONG
            )
        }.otherwise {
            @Suppress("DEPRECATION")
            specBuilder.setUserAuthenticationValidityDurationSeconds(timeout)
        }

        KeyPairGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_EC, "AndroidKeyStore"
        ).run {
            initialize(specBuilder.build())
            generateKeyPair()
        }

    }

    private fun verifyAuthentication(authKey: KeyStore.PrivateKeyEntry): UserAuthenticationStatus {
        val signature = Signature.getInstance("SHA256withECDSA")

        return try {
            signature.initSign(authKey.privateKey)
            signature.update("Sign me".toByteArray(Charsets.US_ASCII))
            signature.sign()
            UserAuthenticationStatus.SUCCESS
        } catch (userNotAuthenticated: UserNotAuthenticatedException) {
            Log.d(TAG, "verifyAuthentication: AuthResult.USER_NOT_AUTHENTICATED")
            UserAuthenticationStatus.USER_NOT_AUTHENTICATED
        } catch (keyPermanentlyInvalidatedException: KeyPermanentlyInvalidatedException) {
            Log.d(TAG, "verifyAuthentication: AuthResult.KEY_PERMANENTLY_INVALIDATED")
            UserAuthenticationStatus.KEY_PERMANENTLY_INVALIDATED
        }
    }

    private fun getKey(): KeyStore.PrivateKeyEntry? =
        keystore.getEntry(KEY_ALIAS, null) as KeyStore.PrivateKeyEntry?

    companion object {
        const val KEY_ALIAS = "USER_AUTH"
        const val TAG = "BiometricProtection"
    }

}