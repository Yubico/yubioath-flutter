package com.yubico.authenticator

import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LiveData
import com.yubico.authenticator.oath.jsonSerializer
import io.flutter.plugin.common.EventChannel
import kotlinx.serialization.encodeToString

inline fun <reified T> LiveData<T>.streamTo(lifecycleOwner: LifecycleOwner, channel: EventChannel) {
    var sink: EventChannel.EventSink? = null

    channel.setStreamHandler(object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            sink = events
            events.success(value?.let(jsonSerializer::encodeToString) ?: "null")
        }

        override fun onCancel(arguments: Any?) {
            sink = null
        }
    })

    observe(lifecycleOwner) {
        sink?.success(it?.let(jsonSerializer::encodeToString) ?: "null")
    }
}