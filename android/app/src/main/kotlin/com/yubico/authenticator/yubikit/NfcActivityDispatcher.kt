package com.yubico.authenticator.yubikit

import android.app.Activity
import android.nfc.NfcAdapter
import android.nfc.Tag
import com.yubico.authenticator.MainActivity
import com.yubico.authenticator.logging.Log
import com.yubico.yubikit.android.transport.nfc.NfcConfiguration
import com.yubico.yubikit.android.transport.nfc.NfcDispatcher
import com.yubico.yubikit.android.transport.nfc.NfcReaderDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

class NfcActivityDispatcher(private val coroutineScope: CoroutineScope) : NfcDispatcher {

    private lateinit var adapter: NfcAdapter
    private lateinit var yubikitNfcDispatcher: NfcReaderDispatcher

    override fun enable(
        activity: Activity,
        nfcConfiguration: NfcConfiguration,
        handler: NfcDispatcher.OnTagHandler
    ) {

        adapter = NfcAdapter.getDefaultAdapter(activity)
        yubikitNfcDispatcher = NfcReaderDispatcher(adapter)

        Log.i(TAG, "enabling yubikit NFC activity dispatcher")
        yubikitNfcDispatcher.enable(
            activity,
            nfcConfiguration,
            TagInterceptor(activity as MainActivity, coroutineScope, handler)
        )

    }

    override fun disable(activity: Activity) {
        yubikitNfcDispatcher.disable(activity)
        Log.i(TAG, "disabling yubikit NFC activity dispatcher")
    }

    class TagInterceptor(
        private val activity: MainActivity,
        private val coroutineScope: CoroutineScope,
        private val tagHandler: NfcDispatcher.OnTagHandler
    ) : NfcDispatcher.OnTagHandler {
        override fun onTag(tag: Tag) {
            coroutineScope.launch {
                activity.appMethodChannel.nfcActivityStateChanged(NfcActivityState.TAG_PRESENT)
                delay(500)
                activity.appMethodChannel.nfcActivityStateChanged(NfcActivityState.PROCESSING_STARTED)
                delay(500)
                Log.i(TAG, "Calling original onTag")
                tagHandler.onTag(tag)
                delay(500)
                Log.i(TAG, "Marking call as successful")
                activity.appMethodChannel.nfcActivityStateChanged(NfcActivityState.PROCESSING_FINISHED)
//                    Log.i(TAG, "Marking call as interrupted")
//                    activity.appMethodChannel.nfcActivityStateChanged(NfcActivityState.PROCESSING_INTERRUPTED.value)
                delay(500)
                activity.appMethodChannel.nfcActivityStateChanged(NfcActivityState.TAG_PRESENT)
            }
        }

    }

    companion object {
        private const val TAG = "NfcActivityDispatcher"
    }

}