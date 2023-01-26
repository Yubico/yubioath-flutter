package com.yubico.authenticator.di

import android.content.Context
import com.yubico.authenticator.AppPreferences
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent

@InstallIn(SingletonComponent::class)
@Module
object AppPreferencesModule {

    @Provides
    fun provideAppPreferences(@ApplicationContext appContext: Context) : AppPreferences {
        return AppPreferences(appContext)
    }
}