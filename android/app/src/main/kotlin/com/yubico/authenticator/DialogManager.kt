package com.yubico.authenticator

import com.yubico.authenticator.api.Pigeon.*
import com.yubico.authenticator.logging.Log
import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

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
            _fDialogApi.showDialogApi(message) { }
        }.also {
            onCancelled = cancelled
        }

    fun closeDialog(onClosed: OnDialogClosed) {
        _fDialogApi.closeDialogApi {
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