/*
 * Copyright (C) 2023 Yubico.
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

package com.yubico.authenticator.oath.data

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

typealias YubiKitCode = com.yubico.yubikit.oath.Code

@Serializable
data class Code(
    val value: String? = null,
    @SerialName("valid_from")
    @Suppress("unused")
    val validFrom: Long,
    @SerialName("valid_to")
    @Suppress("unused")
    val validTo: Long
) {

    companion object {
        fun from(code: YubiKitCode?): Code? =
            code?.let {
                Code(
                    it.value,
                    it.validFrom / 1000,
                    it.validUntil / 1000
                )
            }
    }
}