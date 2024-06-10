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

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import com.yubico.authenticator.databinding.AppWidgetConfigureBinding

class AppWidgetConfigureActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    private var onClickListener = View.OnClickListener {
        val context = this@AppWidgetConfigureActivity

        saveWidgetPreference(context, appWidgetId, "")

        val appWidgetManager = AppWidgetManager.getInstance(context)
        updateAppWidget(context, appWidgetManager, appWidgetId)

        val resultValue = Intent()
        resultValue.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        setResult(RESULT_OK, resultValue)
        finish()
    }
    private lateinit var binding: AppWidgetConfigureBinding

    public override fun onCreate(icicle: Bundle?) {
        super.onCreate(icicle)

        setResult(RESULT_CANCELED)

        binding = AppWidgetConfigureBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.addButton.setOnClickListener(onClickListener)

        // Find the widget id from the intent.
        val intent = intent
        val extras = intent.extras
        if (extras != null) {
            appWidgetId = extras.getInt(
                AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID
            )
        }

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        loadWidgetPreference(this@AppWidgetConfigureActivity, appWidgetId)
    }

}

internal fun saveWidgetPreference(context: Context, appWidgetId: Int, text: String) {
    // TODO implement
}

internal fun loadWidgetPreference(context: Context, appWidgetId: Int): String {
    // TODO implement
    return ""
}

internal fun deleteWidgetPreference(context: Context, appWidgetId: Int) {
    // TODO implement
}