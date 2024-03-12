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
import com.yubico.authenticator.ChannelData
import com.yubico.authenticator.fido.data.FidoCredential
import com.yubico.authenticator.fido.data.Session

class FidoViewModel : ViewModel() {
    private val _sessionState = MutableLiveData<ChannelData<Session?>>()
    val sessionState: LiveData<ChannelData<Session?>> = _sessionState

    fun setSessionState(sessionState: Session?) {
        _sessionState.postValue(ChannelData(sessionState))
    }

    fun clearSessionState() {
        _sessionState.postValue(ChannelData.empty())
    }

    fun setSessionLoadingState() {
        _sessionState.postValue(ChannelData.loading())
    }

    private val _credentials = MutableLiveData<ChannelData<List<FidoCredential>?>>()
    val credentials: LiveData<ChannelData<List<FidoCredential>?>> = _credentials

    fun setCredentialsLoadingState() {
        _credentials.postValue(ChannelData.loading())
    }

    fun updateCredentials(credentials: List<FidoCredential>) {
        _credentials.postValue(ChannelData(credentials))
    }

    fun clearCredentials() {
        _credentials.postValue(ChannelData.empty())
    }

    fun removeCredential(rpId: String, credentialId: String) {
        _credentials.postValue(ChannelData(_credentials.value?.data?.filter {
            it.credentialId != credentialId || it.rpId != rpId
        }))
    }

    private val _resetState = MutableLiveData(FidoResetState.Remove.value)
    val resetState: LiveData<String> = _resetState

    fun updateResetState(resetState: FidoResetState) {
        _resetState.postValue(resetState.value)
    }
}