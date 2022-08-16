package com.yubico.authenticator

import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

typealias OnDialogCancelled = () -> Unit

class DialogManager(messenger: BinaryMessenger, private val coroutineScope: CoroutineScope) {
    private val channel =
        FlutterChannel(messenger, "com.yubico.authenticator.channel.dialog")

    private var onCancelled: OnDialogCancelled? = null

    init {
        channel.setHandler(coroutineScope) { method, args ->
            when (method) {
                "cancel" -> dialogClosed()
                else -> throw NotImplementedError()
            }
        }
    }

    fun showDialog(message: String, cancelled: OnDialogCancelled?) =
        coroutineScope.launch {
            channel.call("show", Json.encodeToString(mapOf("message" to message)))
        }.also {
            onCancelled = cancelled
        }

    suspend fun updateDialogState(title: String? = null, description: String? = null, icon: String? = null, delayMs: Long? = null) {
        channel.call(
            "state",
            Json.encodeToString(mapOf("title" to title, "description" to description, "icon" to icon))
        )
        if (delayMs != null) {
            delay(delayMs)
        }
    }

    suspend fun closeDialog() {
        channel.call("close")
    }

    private suspend fun dialogClosed(): String {
        onCancelled?.invoke()
        return FlutterChannel.NULL
    }

    companion object {
        const val TAG = "dialogManager"
    }
}