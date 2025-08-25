/*
 * Copyright (C) 2023-2024 Yubico.
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

package com.yubico.authenticator.yubikit

enum class NfcState(val value: Int) {
    DISABLED(0),
    IDLE(1),
    ONGOING(2),
    SUCCESS(3),
    FAILURE(4),
    WAIT_FOR_REMOVAL(5),
    USB_ACTIVITY_ONGOING(6),
    USB_ACTIVITY_SUCCESS(7),
    USB_ACTIVITY_FAILURE(8);

    companion object {

        private var _waitForNfcKeyRemoval: Boolean = false
        var waitForNfcKeyRemoval: Boolean
            get() {
                val value = _waitForNfcKeyRemoval
                _waitForNfcKeyRemoval = false  // Reset after read
                return value
            }
            set(value) {
                _waitForNfcKeyRemoval = value
            }

        fun getSuccessState(): NfcState =
            if (waitForNfcKeyRemoval)
                WAIT_FOR_REMOVAL
            else
                SUCCESS

        fun getFailureState(): NfcState = FAILURE.also { waitForNfcKeyRemoval = false }
    }
}