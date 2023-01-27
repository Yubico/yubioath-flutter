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

import com.yubico.authenticator.device.Version

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

typealias YubiKitOathSession = com.yubico.yubikit.oath.OathSession

@Serializable
data class Session(
    @SerialName("device_id")
    val deviceId: String,
    @SerialName("version")
    val version: Version,
    @SerialName("has_key")
    val isAccessKeySet: Boolean,
    @SerialName("remembered")
    val isRemembered: Boolean,
    @SerialName("locked")
    val isLocked: Boolean
) {
    @SerialName("keystore")
    @Suppress("unused")
    val keystoreState: String = "unknown"

    constructor(oathSession: YubiKitOathSession, isRemembered: Boolean)
            : this(
        oathSession.deviceId,
        Version(
            oathSession.version.major,
            oathSession.version.minor,
            oathSession.version.micro
        ),
        oathSession.isAccessKeySet,
        isRemembered,
        oathSession.isLocked
    )
}