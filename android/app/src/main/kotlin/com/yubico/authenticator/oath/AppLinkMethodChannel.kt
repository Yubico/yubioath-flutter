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

package com.yubico.authenticator.oath

import android.net.Uri
import androidx.annotation.UiThread
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class AppLinkMethodChannel(messenger: BinaryMessenger) {
    private val logger = org.slf4j.LoggerFactory.getLogger(AppLinkMethodChannel::class.java)
    private val methodChannel = MethodChannel(messenger, "app.link.methods")

    @UiThread
    fun handleUri(uri: Uri) {
        logger.trace("Handling URI: {}", uri)
        methodChannel.invokeMethod(
            "handleOtpAuthLink",
            JSONObject(mapOf("link" to uri.toString())).toString()
        )
    }

    companion object {
        const val TAG = "AppLinkMethodChannel"
    }
}