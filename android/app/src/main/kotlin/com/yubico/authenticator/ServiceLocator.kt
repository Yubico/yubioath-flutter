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

package com.yubico.authenticator

import android.content.Context
import com.yubico.authenticator.data.DefaultDeviceRepository
import com.yubico.authenticator.data.DeviceModel
import com.yubico.authenticator.data.DeviceRepository
import com.yubico.authenticator.data.YubiKitDeviceModel
import com.yubico.yubikit.android.YubiKitManager

class ServiceLocator(applicationContext: Context) {

    private val yubiKitManager = YubiKitManager(applicationContext)
    private val deviceModel : DeviceModel = YubiKitDeviceModel(yubiKitManager)
    private val deviceRepository : DeviceRepository = DefaultDeviceRepository(deviceModel)
    private val appPreferences : AppPreferences = AppPreferences(applicationContext)
    private val yubiKitController : YubikitController = DefaultYubikitController(yubiKitManager, appPreferences)


    fun provideYubiKitController() = yubiKitController
    fun provideAppPreferences() = appPreferences
}