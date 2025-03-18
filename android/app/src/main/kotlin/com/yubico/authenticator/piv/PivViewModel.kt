/*
 * Copyright (C) 2025 Yubico.
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

package com.yubico.authenticator.piv

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import com.yubico.authenticator.ViewModelData
import com.yubico.authenticator.piv.data.PivSlot
import com.yubico.authenticator.piv.data.PivState

class PivViewModel : ViewModel() {
    private val _state = MutableLiveData<ViewModelData>()
    val state: LiveData<ViewModelData> = _state

    private val _currentSerial = MutableLiveData<Int>()
    val currentSerial: LiveData<Int> = _currentSerial

    fun state(): PivState? = (_state.value as? ViewModelData.Value<*>)?.data as? PivState?

    fun setState(state: PivState) {
        _state.postValue(ViewModelData.Value(state))
    }

    fun clearState() {
        _state.postValue(ViewModelData.Empty)
    }

    private val _slots = MutableLiveData<List<PivSlot>?>()
    val slots: LiveData<List<PivSlot>?> = _slots

    fun updateSlots(slots: List<PivSlot>?) {
        _slots.postValue(slots)
    }
}