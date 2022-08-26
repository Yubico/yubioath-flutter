package com.yubico.authenticator

import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner

/**
 * LifecycleObserver which invokes [block] in onResume callback only if onResume occurs later
 * than [delayMs] after onPause. Instance needs to be added with Lifecycle.addObserver
 *
 * @param delayMs delay in milliseconds
 * @param block code to be executed after delay
 */
class DelayedResumeAction(private val delayMs: Long, private val block: () -> Unit) :
    DefaultLifecycleObserver {

    private var _startTimeMs: Long = -1

    override fun onPause(owner: LifecycleOwner) {
        super.onPause(owner)
        _startTimeMs = _currentTimeMs
    }

    override fun onResume(owner: LifecycleOwner) {
        super.onResume(owner)
        if (_canInvoke) {
            block.invoke()
        }
    }

    private val _currentTimeMs
        get() = System.currentTimeMillis()

    private val _canInvoke: Boolean
        get() = _startTimeMs != -1L && _currentTimeMs - _startTimeMs > delayMs
}