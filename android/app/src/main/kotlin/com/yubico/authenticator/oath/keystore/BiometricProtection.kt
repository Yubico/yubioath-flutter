package com.yubico.authenticator.oath.keystore

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
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
import java.security.SignatureException
import java.security.spec.ECGenParameterSpec

open class BiometricProtection {

    enum class UserAuthenticationStatus {
        KEY_PERMANENTLY_INVALIDATED,
        USER_NOT_AUTHENTICATED,
        SIGNATURE_FAILED,
        SUCCESS
    }

    open fun getAuthenticationStatus(deviceId: String): UserAuthenticationStatus =
        UserAuthenticationStatus.SUCCESS

    open fun setEnabled(enabled: Boolean) {}
    open fun authenticate(
        deviceId: String,
        onKeyPermanentlyInvalidated: () -> Unit,
        onAuthenticationCancelledOrFailed: () -> Unit,
        onAuthenticationSucceeded: () -> Unit
    ) {
    }
}

@RequiresApi(Build.VERSION_CODES.M)
class BiometricProtectionSinceM(
    activity: FragmentActivity,
    private val appPreferences: AppPreferences
) : BiometricProtection() {

    override fun getAuthenticationStatus(deviceId: String): UserAuthenticationStatus {

        // user is authenticated if the use of biometrics is turned off
        if (!appPreferences.useBiometrics) {
            Log.d(TAG, "Not using biometrics")
            return UserAuthenticationStatus.SUCCESS
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
        onKeyPermanentlyInvalidated: () -> Unit,
        onAuthenticationCancelledOrFailed: () -> Unit,
        onAuthenticationSucceeded: () -> Unit
    ) {
        biometricPrompt.authenticate(AuthenticationCallbacks(
            onAuthenticationError = { err, str ->
                Log.e(TAG, "Biometric authentication error $err: $str")
                onAuthenticationCancelledOrFailed()
            },
            onAuthenticationSucceeded = {
                Log.d(TAG, "Biometric authentication succeeded, verifying authentication key")

                val authKey = getKey()
                if (authKey == null) {
                    onKeyPermanentlyInvalidated().also {
                        Log.e(TAG, "Failed to find authentication key")
                    }
                    return@AuthenticationCallbacks
                }

                when (verifyAuthentication(authKey)) {
                    UserAuthenticationStatus.SUCCESS -> onAuthenticationSucceeded().also {
                        Log.d(TAG, "User is now verified by biometrics")
                    }

                    UserAuthenticationStatus.USER_NOT_AUTHENTICATED -> onAuthenticationCancelledOrFailed().also {
                        Log.e(TAG, "Failed to use the authentication private key")
                    }

                    UserAuthenticationStatus.SIGNATURE_FAILED -> onAuthenticationCancelledOrFailed().also {
                        Log.e(TAG, "Signature with the key pair failed")
                    }

                    UserAuthenticationStatus.KEY_PERMANENTLY_INVALIDATED -> onKeyPermanentlyInvalidated().also {
                        Log.e(TAG, "The private key is not valid for signatures anymore")
                    }

                }
            },
            onAuthenticationFailed = {
                Log.e(
                    TAG,
                    "Error authenticating user, the biometric information does not match!"
                )
                onAuthenticationCancelledOrFailed()
            }
        ))
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
        } catch (signatureException: SignatureException) {
            Log.d(TAG, "verifyAuthentication: AuthResult.SIGNATURE_FAILED")
            UserAuthenticationStatus.SIGNATURE_FAILED
        }
    }

    private fun getKey(): KeyStore.PrivateKeyEntry? =
        keystore.getEntry(KEY_ALIAS, null) as KeyStore.PrivateKeyEntry?

    companion object {
        const val KEY_ALIAS = "USER_AUTH"
        const val TAG = "BiometricProtection"
    }

}