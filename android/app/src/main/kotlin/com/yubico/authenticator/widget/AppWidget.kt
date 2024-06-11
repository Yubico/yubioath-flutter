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

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import com.yubico.authenticator.R

class AppWidget : AppWidgetProvider() {

    companion object {
        var hasCode: Boolean = false
        var latestCode: String = ""
        var latestIssuer: String = ""
        var latestAccountName: String = ""
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
        super.onReceive(context, intent)

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
    } else {
        views.setViewVisibility(R.id.appwidget_tap_key_layout, View.VISIBLE)
        views.setViewVisibility(R.id.appwidget_code_layout, View.GONE)
        views.setTextViewText(R.id.appwidget_text, "")
        views.setTextViewText(R.id.issuer_text, "")
        views.setTextViewText(R.id.account_text, "")

    }
    appWidgetManager.updateAppWidget(appWidgetId, views)
}