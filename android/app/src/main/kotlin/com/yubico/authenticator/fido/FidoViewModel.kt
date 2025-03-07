/*
 * Copyright (C) 2024 Yubico.
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

package com.yubico.authenticator.fido

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import com.yubico.authenticator.ViewModelData
import com.yubico.authenticator.fido.data.FidoCredential
import com.yubico.authenticator.fido.data.FidoFingerprint
import com.yubico.authenticator.fido.data.Session

class FidoViewModel : ViewModel() {
    private val _sessionState = MutableLiveData<ViewModelData>()
    val sessionState: LiveData<ViewModelData> = _sessionState

    fun currentSession() : Session? = (_sessionState.value as? ViewModelData.Value<*>)?.data as? Session?

    fun setSessionState(sessionState: Session) {
        _sessionState.postValue(ViewModelData.Value(sessionState))
    }

    fun clearSessionState() {
        _sessionState.postValue(ViewModelData.Empty)
    }

    private val _credentials = MutableLiveData<List<FidoCredential>?>()
    val credentials: LiveData<List<FidoCredential>?> = _credentials

    fun updateCredentials(credentials: List<FidoCredential>?) {
        _credentials.postValue(credentials)
    }

    fun removeCredential(rpId: String, credentialId: String) {
        _credentials.postValue(_credentials.value?.filter {
            it.credentialId != credentialId || it.rpId != rpId
        })
    }

    private val _resetState = MutableLiveData(FidoResetState.Remove.value)
    val resetState: LiveData<String> = _resetState

    fun updateResetState(resetState: FidoResetState) {
        _resetState.postValue(resetState.value)
    }

    private val _fingerprints = MutableLiveData<List<FidoFingerprint>>()
    val fingerprints: LiveData<List<FidoFingerprint>> = _fingerprints

    fun updateFingerprints(fingerprints: List<FidoFingerprint>) {
        _fingerprints.postValue(fingerprints)
    }

    fun addFingerprint(fingerprint: FidoFingerprint) {
        _fingerprints.postValue(_fingerprints.value?.plus(fingerprint))
    }

    fun removeFingerprint(templateId: String) {
        _fingerprints.postValue(_fingerprints.value?.filter {
            it.templateId != templateId
        })
    }

    fun renameFingerprint(templateId: String, name: String) {
        _fingerprints.postValue(_fingerprints.value?.map {
            if (it.templateId == templateId) {
                FidoFingerprint(templateId, name)
            } else it
        })
    }

    private val _registerFingerprint = MutableLiveData<FidoRegisterFpEvent>()
    val registerFingerprint: LiveData<FidoRegisterFpEvent> = _registerFingerprint

    fun updateRegisterFpState(registerFpState: FidoRegisterFpEvent) {
        _registerFingerprint.postValue(registerFpState)
    }
}