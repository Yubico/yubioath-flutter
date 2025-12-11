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

package com.yubico.authenticator.piv.data

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

typealias YubiKitManagementKeyMetadata = com.yubico.yubikit.piv.ManagementKeyMetadata

@Serializable
data class ManagementKeyMetadata(
    @SerialName("key_type")
    val keyType: Byte,
    @SerialName("default_value")
    val defaultValue: Boolean,
    @SerialName("touch_policy")
    val touchPolicy: Int
) {
    constructor(managementKeyMetadata: YubiKitManagementKeyMetadata) : this(
        managementKeyMetadata.keyType.value,
        managementKeyMetadata.isDefaultValue,
        managementKeyMetadata.touchPolicy.value
    )
}
