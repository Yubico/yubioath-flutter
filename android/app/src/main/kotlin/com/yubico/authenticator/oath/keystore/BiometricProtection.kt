package com.yubico.authenticator.oath.keystore

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.security.keystore.UserNotAuthenticatedException
import androidx.annotation.RequiresApi
import androidx.fragment.app.FragmentActivity
import com.yubico.authenticator.AppPreferences
import com.yubico.authenticator.compatUtil
import com.yubico.authenticator.logging.Log
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature
import java.security.spec.ECGenParameterSpec

open class BiometricProtection {
    open fun isUserAuthenticated(deviceId: String): Boolean = true
    open fun setEnabled(enabled: Boolean) {}
    open fun authenticate(
        deviceId: String,
        onAuthenticationExpired: () -> Unit,
        onAuthenticationCancelledOrFailed: () -> Unit,
        onAuthenticationSucceeded: () -> Unit
    ): Boolean = true
}

@RequiresApi(Build.VERSION_CODES.M)
class BiometricProtectionSinceM(
    activity: FragmentActivity,
    private val appPreferences: AppPreferences
) : BiometricProtection() {

    private val biometricPrompt = OathBiometricPrompt(activity)

    override fun isUserAuthenticated(deviceId: String): Boolean {

        // user is authenticated if the use of biometrics is turned off
        if (!appPreferences.useBiometrics) {
            Log.d(TAG, "Not using biometrics")
            return true
        }

        if (!keystore.containsAlias(getAlias(deviceId))) {
            // the deviceId does not have it's access key secret in the keystore
            // we don't need to verify user authentication
            Log.d(TAG, "Access key for $deviceId is not remembered")
            return true
        }

        val authKey = getKey()
        if (authKey == null) {
            Log.d(TAG, "Could not find auth key for biometric authentication")
            return false
        }

        return verifySigning(initializeSignature() ?: return false)
    }

    override fun authenticate(
        deviceId: String,
        onAuthenticationExpired: () -> Unit,
        onAuthenticationCancelledOrFailed: () -> Unit,
        onAuthenticationSucceeded: () -> Unit
    ): Boolean {

        if (isUserAuthenticated(deviceId)) {
            return true
        }

        val authKey = getKey()
        if (authKey == null) {
            Log.d(TAG, "Failed to find authentication key")
            return false
        }

        val callbacks = AuthenticationCallbacks(
            onAuthenticationError = { err, str ->
                Log.e(TAG, "Biometric authentication error $err: $str")
                onAuthenticationCancelledOrFailed()
            },
            onAuthenticationSucceeded = {
                Log.d(TAG, "Biometric authentication succeeded, verifying authentication key")
                val signature = initializeSignature()
                if (signature == null) {
                    Log.e(
                        TAG,
                        "The private key is not valid for signatures anymore - removing remembered passwords"
                    )
                    onAuthenticationExpired()
                    return@AuthenticationCallbacks
                }

                if (!verifySigning(signature)) {
                    Log.e(TAG, "Failed to use the authentication private key")
                    onAuthenticationCancelledOrFailed()
                }

                Log.d(TAG, "User is now verified by biometrics")
                onAuthenticationSucceeded()
            },
            onAuthenticationFailed = {
                Log.e(TAG, "Error authenticating user, the biometric information does not match!")
                onAuthenticationCancelledOrFailed()
            }
        )

        biometricPrompt.authenticate(callbacks)

        return true
    }

    companion object {
        const val KEY_ALIAS = "USER_AUTH"
        const val TAG = "BiometricProtection"
    }

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

    override fun setEnabled(enabled: Boolean) {

        if (!enabled) {
            // remove authentication key
            Log.d(TAG, "Disabling biometric protection")
            keystore.deleteEntry(KEY_ALIAS)
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


    private fun initializeSignature(): Signature? {

        val authKey = getKey()

        if (authKey == null) {
            Log.i(TAG, "Could not find auth key for biometric authentication")
            return null
        }

        return try {
            val signature = Signature.getInstance("SHA256withECDSA")

            // initSign will fail, if the user is not authenticated or if the key is not valid
            signature.initSign(authKey.privateKey)
            signature
        } catch (t: Throwable) {
            Log.e(TAG, "Failed to initialize signature with the private key: ${t.message}")
            null
        }
    }

    private fun verifySigning(signature: Signature): Boolean =
        try {
            signature.update("Sign me".toByteArray(Charsets.US_ASCII))
            // sign will fail if the user is not authenticated
            signature.sign()
            true
        } catch (userNotAuthenticated: UserNotAuthenticatedException) {
            false
        }

    private fun getKey(): KeyStore.PrivateKeyEntry? =
        keystore.getEntry(KEY_ALIAS, null) as KeyStore.PrivateKeyEntry?

}