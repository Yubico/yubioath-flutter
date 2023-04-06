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

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope

class AppContext(messenger: BinaryMessenger, coroutineScope: CoroutineScope, private val appViewModel: MainViewModel)  {
    private val channel = MethodChannel(messenger, "android.state.appContext")
    private val logger = org.slf4j.LoggerFactory.getLogger(AppContext::class.java)

    init {
        channel.setHandler(coroutineScope) { method, args ->
            when (method) {
                "setContext" -> setContext(args["index"] as Int)
                else -> throw NotImplementedError()
            }
        }
    }

    private suspend fun setContext(subPageIndex: Int): String {
        val appContext = OperationContext.getByValue(subPageIndex)
        appViewModel.setAppContext(appContext)
        logger.debug("App context is now {}", appContext)
        return NULL
    }
}