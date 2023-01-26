package com.yubico.authenticator.di

import android.content.Context
import com.yubico.yubikit.android.YubiKitManager
import com.yubico.yubikit.android.transport.nfc.NfcConfiguration
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.components.ActivityComponent
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@InstallIn(SingletonComponent::class)
@Module
object YubiKitModule {

    @Provides
    @Singleton
    fun provideYubiKitManager(@ApplicationContext appContext: Context) : YubiKitManager {
        return YubiKitManager(appContext)
    }

}