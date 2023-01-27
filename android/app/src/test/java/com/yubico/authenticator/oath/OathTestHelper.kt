/*
 * Copyright (C) 2022-2023 Yubico.
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

import com.yubico.authenticator.oath.data.Code
import com.yubico.authenticator.oath.data.CodeType
import com.yubico.authenticator.oath.data.Credential

object OathTestHelper {

    // create a TOTP credential with default or custom parameters
    // if not specified, default values for deviceId, name and issuer will use a unique value
    // which is incremented on every call to this function
    fun totp(
        deviceId: String = nextDevice(),
        name: String = nextName(),
        issuer: String? = nextIssuer(),
        touchRequired: Boolean = false,
        period: Int = 30
    ) = cred(deviceId, name, issuer, CodeType.TOTP, touchRequired, period)

    // create a HOTP credential with default or custom parameters
    // if not specified, default values for deviceId, name and issuer will use a unique value
    // which is incremented on every call to this function
    fun hotp(
        deviceId: String = nextDevice(),
        name: String = nextName(),
        issuer: String = nextIssuer(),
        touchRequired: Boolean = false,
        period: Int = 30
    ) = cred(deviceId, name, issuer, CodeType.HOTP, touchRequired, period)

    private fun cred(
        deviceId: String = nextDevice(),
        name: String = nextName(),
        issuer: String? = nextIssuer(),
        type: CodeType,
        touchRequired: Boolean = false,
        period: Int = 30
    ) =
        Credential(
            deviceId = deviceId,
            id = """otpauth://${type.name}/${name}?secret=aabbaabbaabbaabb&issuer=${issuer}""",
            codeType = type,
            period = period,
            issuer = issuer,
            accountName = name,
            touchRequired = touchRequired
        )
    // create a Code with default or custom parameters
    fun code(
        value: String = "111111",
        from: Long = 1000,
        to: Long = 2000
    ) = Code(value, from, to)

    fun emptyCredentials() = emptyMap<Credential, Code>()

    private var nameCounter = 0
    private fun nextName(): String {
        return "name${nameCounter++}"
    }

    private var issuerCounter = 0
    private fun nextIssuer(): String {
        return "issuer${issuerCounter++}"
    }

    private var deviceCounter = 0
    private fun nextDevice(): String {
        return "deviceId${deviceCounter++}"
    }
}