/*
 * Copyright (C) 2022 Yubico.
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

import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.os.Build
import android.os.PersistableBundle
import com.yubico.authenticator.logging.Log

object ClipboardUtil {

    private const val TAG = "ClipboardUtil"

    fun setPrimaryClip(context: Context, toClipboard: String, isSensitive: Boolean) {
        try {
            val clipboardManager =
                context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

            val clipData = ClipData.newPlainText(toClipboard, toClipboard)
            clipData.apply {
                if (SdkVersion.ge(Build.VERSION_CODES.TIRAMISU)) {
                    description.extras = PersistableBundle().apply {
                        putBoolean(ClipDescription.EXTRA_IS_SENSITIVE, isSensitive)
                    }
                }
            }

            clipboardManager.setPrimaryClip(clipData)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set string to clipboard", e.stackTraceToString())
            throw UnsupportedOperationException()
        }
    }

}