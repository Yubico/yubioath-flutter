package com.yubico.authenticator.data

import com.yubico.authenticator.logging.Log
import com.yubico.authenticator.oath.data.CredentialWithCode
import com.yubico.authenticator.oath.data.Session
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch
import java.util.concurrent.Executors

interface OathRepository {
    val oathSession: Flow<Session?>
    val oathCredentials: Flow<List<CredentialWithCode>?>

    suspend fun reset(): String

    suspend fun unlock(password: String, remember: Boolean): String

    suspend fun setPassword(current: String?, password: String): String

    suspend fun unsetPassword(current: String): String

    suspend fun forgetPassword(): String

    suspend fun calculate(credentialId: String): String

    suspend fun addAccount(uri: String, requireTouch: Boolean): String

    suspend fun renameAccount(uri: String, name: String, issuer: String?): String

    suspend fun deleteAccount(credentialId: String): String

    suspend fun addAccountToAny(uri: String, requireTouch: Boolean): String
}

class DefaultOathRepository(private val oathModel: OathModel) : OathRepository {

    override val oathSession: Flow<Session?>
        get() = oathModel.getSession()

    override val oathCredentials: Flow<List<CredentialWithCode>?>
        get() = oathModel.getCredentials()

    override suspend fun reset(): String {
        Log.d(TAG, "reset")
        return "{}"
    }

    override suspend fun unlock(password: String, remember: Boolean): String {
        Log.d(TAG, "unlock")
        return "{}"
    }

    override suspend fun setPassword(current: String?, password: String): String {
        Log.d(TAG, "setPassword")
        return "{}"
    }

    override suspend fun unsetPassword(current: String): String {
        Log.d(TAG, "unsetPassword")
        return "{}"
    }

    override suspend fun forgetPassword(): String {
        Log.d(TAG, "forgetPassword")
        return "{}"
    }

    override suspend fun calculate(credentialId: String): String {
        Log.d(TAG, "calculate")
        return "{}"
    }

    override suspend fun addAccount(uri: String, requireTouch: Boolean): String {
        Log.d(TAG, "addAccount")
        return "{}"
    }

    override suspend fun renameAccount(uri: String, name: String, issuer: String?): String =
        oathModel.renameAccount(uri, name, issuer)

    override suspend fun deleteAccount(credentialId: String): String {
        Log.d(TAG, "deleteAccount")
        return "{}"
    }

    override suspend fun addAccountToAny(uri: String, requireTouch: Boolean): String {
        Log.d(TAG, "addAccountToAny")
        return "{}"
    }


    companion object {
        const val TAG = "OathRepository"
    }
}