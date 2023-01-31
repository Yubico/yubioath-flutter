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

import android.annotation.TargetApi
import android.content.Context
import android.os.Build
import com.yubico.authenticator.data.DefaultDeviceRepository
import com.yubico.authenticator.data.DefaultOathRepository
import com.yubico.authenticator.data.DeviceModel
import com.yubico.authenticator.data.DeviceRepository
import com.yubico.authenticator.data.OathModel
import com.yubico.authenticator.data.OathRepository
import com.yubico.authenticator.data.YubiKitDeviceModel
import com.yubico.authenticator.data.YubiKitOathModel
import com.yubico.authenticator.oath.KeyManager
import com.yubico.authenticator.oath.keystore.ClearingMemProvider
import com.yubico.authenticator.oath.keystore.KeyProvider
import com.yubico.authenticator.oath.keystore.KeyStoreProvider
import com.yubico.authenticator.oath.keystore.SharedPrefProvider
import com.yubico.yubikit.android.YubiKitManager
import io.flutter.plugin.common.BinaryMessenger

class ServiceLocator(applicationContext: Context) {

    private val appPreferences: AppPreferences = AppPreferences(applicationContext)
    private val yubiKitManager = YubiKitManager(applicationContext)

    private val memoryKeyProvider = ClearingMemProvider()
    private val keyManager by lazy {
        KeyManager(
            compatUtil.from(Build.VERSION_CODES.M) {
                createKeyStoreProviderM()
            }.otherwise(
                SharedPrefProvider(applicationContext)
            ), memoryKeyProvider
        )
    }

    private var flutterBinaryMessenger : BinaryMessenger? = null

    @TargetApi(Build.VERSION_CODES.M)
    private fun createKeyStoreProviderM(): KeyProvider = KeyStoreProvider()

    private val deviceModel: DeviceModel = YubiKitDeviceModel()
    private val oathModel: OathModel = YubiKitOathModel(keyManager, memoryKeyProvider, appPreferences, deviceModel)



    private val deviceRepository: DeviceRepository = DefaultDeviceRepository(deviceModel, oathModel)
    private val oathRepository: OathRepository = DefaultOathRepository(oathModel)



    private val yubiKitController: YubikitController =
        DefaultYubikitController(applicationContext, yubiKitManager, deviceRepository, appPreferences)


    fun provideYubiKitController() = yubiKitController
    fun provideAppPreferences() = appPreferences

    fun provideDeviceRepository() = deviceRepository
    fun provideOathRepository() = oathRepository

    fun setFlutterBinaryMessenger(messenger: BinaryMessenger?) {
        flutterBinaryMessenger = messenger
    }
    fun provideFlutterBinaryMessenger() = flutterBinaryMessenger
}