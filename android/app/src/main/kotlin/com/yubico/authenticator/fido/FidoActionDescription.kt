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

const val dialogDescriptionFidoIndex = 200

enum class FidoActionDescription(private val value: Int) {
    Reset(0),
    Unlock(1),
    SetPin(2),
    DeleteCredential(3),
    DeleteFingerprint(4),
    RenameFingerprint(5),
    RegisterFingerprint(6),
    EnableEnterpriseAttestation(7),
    ActionFailure(8);

    val id: Int
        get() = value + dialogDescriptionFidoIndex
}