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

package com.yubico.authenticator.management

import com.yubico.authenticator.NULL
import com.yubico.authenticator.device.DeviceManager
import com.yubico.authenticator.setHandler
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.asCoroutineDispatcher
import java.util.concurrent.Executors

class ManagementHandler(
    messenger: BinaryMessenger,
    deviceManager: DeviceManager
) {
    private val channel = MethodChannel(messenger, "android.management.methods")

    private val dispatcher = Executors.newSingleThreadExecutor().asCoroutineDispatcher()
    private val coroutineScope = CoroutineScope(SupervisorJob() + dispatcher)
    private val connectionHelper = ManagementConnectionHelper(deviceManager)

    init {
        channel.setHandler(coroutineScope) { method, _ ->
            when (method) {
                "deviceReset" -> deviceReset()

                else -> throw NotImplementedError()
            }
        }
    }

    private suspend fun deviceReset(): String =
        connectionHelper.useSession { managementSession ->
            managementSession.deviceReset()
            NULL
        }
}