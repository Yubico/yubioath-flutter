package com.yubico.authenticator

import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.*
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

typealias OnDialogCancelled = suspend () -> Unit

enum class Icon(val value: String) {
    NFC("nfc"),
    SUCCESS("success"),
    ERROR("error");
}

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

    fun showDialog(icon: Icon, title: String, description: String, cancelled: OnDialogCancelled?) {
        onCancelled = cancelled
        coroutineScope.launch {
            channel.call(
                "show",
                Json.encodeToString(
                    mapOf(
                        "title" to title,
                        "description" to description,
                        "icon" to icon.value
                    )
                )
            )
        }
    }

    suspend fun updateDialogState(
        icon: Icon? = null,
        title: String? = null,
        description: String? = null
    ) {
        channel.call(
            "state",
            Json.encodeToString(
                mapOf(
                    "title" to title,
                    "description" to description,
                    "icon" to icon?.value
                )
            )
        )
    }

    fun closeDialog() {
        coroutineScope.launch {
            channel.call("close")
        }
    }

    private suspend fun dialogClosed(): String {
        onCancelled?.let {
            onCancelled = null
            withContext(Dispatchers.Main) {
                it.invoke()
            }
        }
        return FlutterChannel.NULL
    }

    companion object {
        const val TAG = "dialogManager"
    }
}