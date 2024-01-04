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

import com.yubico.authenticator.fido.data.Session
import com.yubico.authenticator.fido.data.FidoCredential

class FidoViewModel : ViewModel() {
    private val _sessionState = MutableLiveData<Session?>()
    val sessionState: LiveData<Session?> = _sessionState

    fun setSessionState(sessionState: Session?) {
        _sessionState.postValue(sessionState)
    }

    private val _credentials = MutableLiveData<List<FidoCredential>>()
    val credentials: LiveData<List<FidoCredential>> = _credentials

    fun updateCredentials(credentials: List<FidoCredential>) {
        _credentials.postValue(credentials)
    }
}