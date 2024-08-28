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

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

typealias OnDialogCancelled = suspend () -> Unit

class DialogManager(messenger: BinaryMessenger, private val coroutineScope: CoroutineScope) {
    private val channel =
        MethodChannel(messenger, "com.yubico.authenticator.channel.dialog")

    private var onCancelled: OnDialogCancelled? = null

    init {
        channel.setHandler(coroutineScope) { method, _ ->
            when (method) {
                "cancel" -> dialogClosed()
                else -> throw NotImplementedError()
            }
        }
    }

    fun showDialog(cancelled: OnDialogCancelled?) {
        onCancelled = cancelled
        coroutineScope.launch {
            channel.invoke("show", null)
        }
    }

    suspend fun closeDialog() {
        channel.invoke("close", NULL)
    }

    private suspend fun dialogClosed(): String {
        onCancelled?.let {
            onCancelled = null
            withContext(Dispatchers.Main) {
                it.invoke()
            }
        }
        return NULL
    }
}