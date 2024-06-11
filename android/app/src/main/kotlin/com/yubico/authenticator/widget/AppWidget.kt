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

package com.yubico.authenticator.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import android.widget.Toast
import com.yubico.authenticator.ClipboardUtil
import com.yubico.authenticator.MainActivity
import com.yubico.authenticator.R
import com.yubico.authenticator.compatUtil

class AppWidget : AppWidgetProvider() {

    companion object {
        var hasCode: Boolean = false
        var latestCode: String = ""
        var latestIssuer: String = ""
        var latestAccountName: String = ""

        const val ACTION_OPEN_APP = "OPEN_APP"
        const val ACTION_COPY_CODE = "COPY_CODE"
        const val EXTRA_CODE = "CODE"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            deleteWidgetPreference(context, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
    }

    override fun onDisabled(context: Context) {
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        when (intent?.action) {
            ACTION_OPEN_APP -> {
                val mainAppIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context?.startActivity(mainAppIntent)
            }

            ACTION_COPY_CODE -> {

                context?.let {
                    val code = intent.extras?.getString(EXTRA_CODE)
                    code?.let {
                        ClipboardUtil.setPrimaryClip(context, code, false)
                        compatUtil.until(Build.VERSION_CODES.TIRAMISU) {
                            Toast.makeText(context, "Copied code to clipboard", Toast.LENGTH_LONG)
                                .show()
                        }
                    }
                }

            }

            else -> super.onReceive(context, intent)
        }


    }
}

internal fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int
) {
    val views = RemoteViews(context.packageName, R.layout.app_widget)
    if (AppWidget.hasCode) {
        views.setViewVisibility(R.id.appwidget_tap_key_layout, View.GONE)
        views.setViewVisibility(R.id.appwidget_code_layout, View.VISIBLE)
        val renderCode = AppWidget.latestCode.chunked(3).joinToString(" ")
        views.setTextViewText(R.id.appwidget_text, renderCode)
        views.setTextViewText(R.id.issuer_text, AppWidget.latestIssuer)
        views.setTextViewText(R.id.account_text, AppWidget.latestAccountName)

        // open app
        val copyCodeIntent = Intent(context, AppWidget::class.java).apply {
            action = AppWidget.ACTION_COPY_CODE
            putExtra(AppWidget.EXTRA_CODE, AppWidget.latestCode)
        }
        val copyCodePendingIntent =
            PendingIntent.getBroadcast(context, 0, copyCodeIntent, PendingIntent.FLAG_IMMUTABLE)
        views.setOnClickPendingIntent(R.id.appwidget_copy_btn, copyCodePendingIntent)

    } else {
        views.setViewVisibility(R.id.appwidget_tap_key_layout, View.VISIBLE)
        views.setViewVisibility(R.id.appwidget_code_layout, View.GONE)
        views.setTextViewText(R.id.appwidget_text, "")
        views.setTextViewText(R.id.issuer_text, "")
        views.setTextViewText(R.id.account_text, "")
    }

    // open app
    val openAppIntent = Intent(context, AppWidget::class.java).apply {
        action = AppWidget.ACTION_OPEN_APP
    }
    val openAppPendingIntent =
        PendingIntent.getBroadcast(context, 0, openAppIntent, PendingIntent.FLAG_IMMUTABLE)
    views.setOnClickPendingIntent(R.id.appwidget, openAppPendingIntent)

    appWidgetManager.updateAppWidget(appWidgetId, views)
}

