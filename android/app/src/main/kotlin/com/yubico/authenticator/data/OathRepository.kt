package com.yubico.authenticator.data

import com.yubico.authenticator.oath.data.CredentialWithCode
import com.yubico.authenticator.oath.data.Session
import kotlinx.coroutines.flow.Flow

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

    override suspend fun reset(): String =
        oathModel.reset()

    override suspend fun unlock(password: String, remember: Boolean): String =
        oathModel.unlock(password, remember)

    override suspend fun setPassword(current: String?, password: String): String =
        oathModel.setPassword(current, password)

    override suspend fun unsetPassword(current: String): String =
        oathModel.unsetPassword(current)

    override suspend fun forgetPassword(): String =
        oathModel.forgetPassword()

    override suspend fun calculate(credentialId: String): String =
        oathModel.calculate(credentialId)

    override suspend fun addAccount(uri: String, requireTouch: Boolean): String =
        oathModel.addAccount(uri, requireTouch)

    override suspend fun renameAccount(uri: String, name: String, issuer: String?): String =
        oathModel.renameAccount(uri, name, issuer)

    override suspend fun deleteAccount(credentialId: String): String =
        oathModel.deleteAccount(credentialId)

    override suspend fun addAccountToAny(uri: String, requireTouch: Boolean): String =
        oathModel.addAccountToAny(uri, requireTouch)

    companion object {
        const val TAG = "OathRepository"
    }
}