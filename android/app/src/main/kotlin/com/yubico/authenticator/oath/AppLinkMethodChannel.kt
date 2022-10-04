package com.yubico.authenticator.oath

import android.net.Uri
import androidx.annotation.UiThread
import com.yubico.authenticator.logging.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class AppLinkMethodChannel(messenger: BinaryMessenger) {
    private val methodChannel = MethodChannel(messenger, "app.link.methods")

    @UiThread
    fun handleUri(uri: Uri) {
        Log.t(TAG, "Handling URI: $uri")
        methodChannel.invokeMethod(
            "handleOtpAuthLink",
            JSONObject(mapOf("link" to uri.toString())).toString()
        )
    }

    companion object {
        const val TAG = "AppLinkMethodChannel"
    }
}