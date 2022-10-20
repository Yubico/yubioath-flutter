/*
 * Copyright (C) 2022 Yubico.
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

class OathViewModel: ViewModel() {
    private val _sessionState = MutableLiveData<Model.Session?>()
    val sessionState: LiveData<Model.Session?> = _sessionState

    fun setSessionState(sessionState: Model.Session?) {
        val oldDeviceId = _sessionState.value?.deviceId
        _sessionState.postValue(sessionState)
        if(oldDeviceId != sessionState?.deviceId) {
            _credentials.postValue(null)
        }
    }

    private val _credentials = MutableLiveData<List<Model.CredentialWithCode>?>()
    val credentials: LiveData<List<Model.CredentialWithCode>?> = _credentials

    fun updateCredentials(credentials: Map<Model.Credential, Model.Code?>): List<Model.CredentialWithCode> {
        val existing = _credentials.value?.associate { it.credential to it.code } ?: mapOf()

        val updated = credentials.map {
            Model.CredentialWithCode(it.key, it.value ?: existing[it.key])
        }

        _credentials.postValue(updated)

        return updated
    }

    fun addCredential(credential: Model.Credential, code: Model.Code?): Model.CredentialWithCode {
        require(credential.deviceId == _sessionState.value?.deviceId) {
            "Cannot add credential for different deviceId"
        }
        return Model.CredentialWithCode(credential, code).also {
            _credentials.postValue(_credentials.value?.plus(it))
        }
    }

    fun renameCredential(
        oldCredential: Model.Credential,
        newCredential: Model.Credential
    ) {
        val existing = _credentials.value!!
        val entry = existing.find { it.credential == oldCredential }!!
        require(entry.credential.deviceId == newCredential.deviceId) {
            "Cannot rename credential for different deviceId"
        }
        _credentials.postValue(existing.minus(entry).plus(Model.CredentialWithCode(newCredential, entry.code)))
    }

    fun removeCredential(credential: Model.Credential) {
        val existing = _credentials.value!!
        val entry = existing.find { it.credential == credential }!!
        _credentials.postValue(existing.minus(entry))
    }

    fun updateCode(credential: Model.Credential, code: Model.Code?) {
        val existing = _credentials.value!!
        val entry = existing.find { it.credential == credential }!!
        _credentials.postValue(existing.minus(entry).plus(Model.CredentialWithCode(credential, code)))
    }
}