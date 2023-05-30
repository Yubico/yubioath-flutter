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

package com.yubico.authenticator

import android.annotation.TargetApi
import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.os.PersistableBundle

import org.slf4j.LoggerFactory

object ClipboardUtil {

    private val logger = LoggerFactory.getLogger(ClipboardUtil::class.java)

    fun setPrimaryClip(context: Context, toClipboard: String, isSensitive: Boolean) {
        try {
            val clipboardManager =
                context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

            val clipData = ClipData.newPlainText(toClipboard, toClipboard)
            compatUtil.from(Build.VERSION_CODES.TIRAMISU) {
                updateExtrasTiramisu(clipData, isSensitive)
            }

            clipboardManager.setPrimaryClip(clipData)
        } catch (e: Exception) {
            logger.error( "Failed to set string to clipboard", e)
            throw UnsupportedOperationException()
        }
    }

    @TargetApi(Build.VERSION_CODES.TIRAMISU)
    private fun updateExtrasTiramisu(clipData: ClipData, isSensitive: Boolean) {
        clipData.description.extras = PersistableBundle().apply {
            putBoolean(ClipDescription.EXTRA_IS_SENSITIVE, isSensitive)
        }
    }
}