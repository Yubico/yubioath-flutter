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

package com.yubico.authenticator.oath

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.CreationExtras
import com.yubico.authenticator.App
import com.yubico.authenticator.data.OathRepository
import com.yubico.authenticator.logging.Log
import com.yubico.authenticator.oath.data.Code
import com.yubico.authenticator.oath.data.Credential
import com.yubico.authenticator.oath.data.CredentialWithCode
import com.yubico.authenticator.oath.data.Session
import com.yubico.authenticator.setHandler
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import java.util.concurrent.Executors

class OathViewModel(repository: OathRepository, messenger: BinaryMessenger): ViewModel() {

    companion object {

        private const val TAG = "OathViewModel"

        val Factory: ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(
                modelClass: Class<T>,
                extras: CreationExtras
            ): T {
                // Get the Application object from extras
                val application = checkNotNull(extras[ViewModelProvider.AndroidViewModelFactory.APPLICATION_KEY])
                // Create a SavedStateHandle for this ViewModel from extras
                val serviceLocator = (application as App).serviceLocator
                return OathViewModel(
                    serviceLocator.provideOathRepository(),
                    serviceLocator.provideFlutterBinaryMessenger()!!
                ) as T
            }
        }
    }

    private val oathChannel = MethodChannel(messenger, "android.oath.methods")
    private val dispatcher = Executors.newSingleThreadExecutor().asCoroutineDispatcher()
    private val coroutineScope = CoroutineScope(SupervisorJob() + dispatcher)

    init {
        // OATH methods callable from Flutter:
        oathChannel.setHandler(coroutineScope) { method, args ->
            when (method) {
                "reset" -> repository.reset()
                "unlock" -> repository.unlock(
                    args["password"] as String,
                    args["remember"] as Boolean
                )

                "setPassword" -> repository.setPassword(
                    args["current"] as String?,
                    args["password"] as String
                )

                "unsetPassword" -> repository.unsetPassword(args["current"] as String)
                "forgetPassword" -> repository.forgetPassword()
                "calculate" -> repository.calculate(args["credentialId"] as String)
                "addAccount" -> repository.addAccount(
                    args["uri"] as String,
                    args["requireTouch"] as Boolean
                )

                "renameAccount" -> repository.renameAccount(
                    args["credentialId"] as String,
                    args["name"] as String,
                    args["issuer"] as String?
                )

                "deleteAccount" -> repository.deleteAccount(args["credentialId"] as String)
                "addAccountToAny" -> repository.addAccountToAny(
                    args["uri"] as String,
                    args["requireTouch"] as Boolean
                )

                else -> throw NotImplementedError()
            }
        }

        // TODO: originally in OathManager
        //lifecycleOwner.lifecycle.addObserver(lifecycleObserver)
    }

    val flowSessionState: Flow<Session?> = repository.oathSession.stateIn(
        scope = viewModelScope,
        initialValue = null,
        started = SharingStarted.WhileSubscribed(5000)
    ).map {
        Log.d(TAG, "Got session state from flow: $it")
        it
    }

    val flowCredentials: Flow<List<CredentialWithCode>?> = repository.oathCredentials.stateIn(
        scope = viewModelScope,
        initialValue = null,
        started = SharingStarted.WhileSubscribed(5000)
    ).map {
        Log.d(TAG, "Got credentials from flow: $it")
        it
    }

    private val _sessionState = MutableLiveData<Session?>()
    val sessionState: LiveData<Session?> = _sessionState
    @Deprecated("New architecture does not use this method")
    fun setSessionState(sessionState: Session?) {
        val oldDeviceId = _sessionState.value?.deviceId
        _sessionState.postValue(sessionState)
        if(oldDeviceId != sessionState?.deviceId) {
            _credentials.postValue(null)
        }
    }

    private val _credentials = MutableLiveData<List<CredentialWithCode>?>()
    val credentials: LiveData<List<CredentialWithCode>?> = _credentials

    @Deprecated("New architecture does not use this method")
    fun updateCredentials(credentials: Map<Credential, Code?>): List<CredentialWithCode> {
        val existing = _credentials.value?.associate { it.credential to it.code } ?: mapOf()

        val updated = credentials.map {
            CredentialWithCode(it.key, it.value ?: existing[it.key])
        }

        _credentials.postValue(updated)

        return updated
    }

    @Deprecated("New architecture does not use this method")
    fun addCredential(credential: Credential, code: Code?): CredentialWithCode {
        require(credential.deviceId == _sessionState.value?.deviceId) {
            "Cannot add credential for different deviceId"
        }
        return CredentialWithCode(credential, code).also {
            _credentials.postValue(_credentials.value?.plus(it))
        }
    }

    @Deprecated("New architecture does not use this method")
    fun renameCredential(
        oldCredential: Credential,
        newCredential: Credential
    ) {
        val existing = _credentials.value!!
        val entry = existing.find { it.credential == oldCredential }!!
        require(entry.credential.deviceId == newCredential.deviceId) {
            "Cannot rename credential for different deviceId"
        }
        _credentials.postValue(existing.minus(entry).plus(CredentialWithCode(newCredential, entry.code)))
    }

    @Deprecated("New architecture does not use this method")
    fun removeCredential(credential: Credential) {
        val existing = _credentials.value!!
        val entry = existing.find { it.credential == credential }!!
        _credentials.postValue(existing.minus(entry))
    }

    @Deprecated("New architecture does not use this method")
    fun updateCode(credential: Credential, code: Code?) {
        val existing = _credentials.value!!
        val entry = existing.find { it.credential == credential }!!
        _credentials.postValue(existing.minus(entry).plus(CredentialWithCode(credential, code)))
    }
}