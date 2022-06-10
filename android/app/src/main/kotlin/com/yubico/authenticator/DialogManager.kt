package com.yubico.authenticator

import com.yubico.authenticator.api.Pigeon.*
import com.yubico.authenticator.logging.Log
import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.*
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

typealias OnDialogClosed = () -> Unit
typealias OnDialogCancelled = () -> Unit

class DialogManager(messenger: BinaryMessenger, private var coroutineScope: CoroutineScope) :
    HDialogApi {

    private val _fDialogApi = FDialogApi(messenger)

    private var onCancelled: OnDialogCancelled? = null

    init {
        HDialogApi.setup(messenger, this)
    }

    fun showDialog(message: String, cancelled: OnDialogCancelled?) =
        coroutineScope.launch(Dispatchers.Main) {
            _fDialogApi.showDialog(message) { }
        }.also {
            onCancelled = cancelled
        }

    suspend fun updateDialogState(title: String? = null, description: String? = null, icon: String? = null, delayMs: Long? = null) {
        withContext(Dispatchers.Main) {
            suspendCoroutine<Boolean> { continuation ->
                _fDialogApi.updateDialogState(title, description, icon) {
                    continuation.resume(true)
                }
            }
            if (delayMs != null) {
                delay(delayMs)
            }
        }
    }

    fun closeDialog(onClosed: OnDialogClosed) {
        _fDialogApi.closeDialog {
            coroutineScope.launch(Dispatchers.Main) {
                onClosed()
            }
        }
    }

    override fun dialogClosed(result: Result<Void>) {
        coroutineScope.launch {
            try {
                onCancelled?.invoke()
                result.success(null)
            } catch (cause: Throwable) {
                Log.d(TAG, "Failed to close dialog during User cancel action")
                result.error(Exception("Failed to close dialog during User cancel action"))
            }
        }
    }

    companion object {
        const val TAG = "dialogManager"
    }

}