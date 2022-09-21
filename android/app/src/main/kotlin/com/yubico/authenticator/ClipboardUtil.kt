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
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
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