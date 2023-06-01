package com.yubico.authenticator.yubikit

import android.app.Activity
import android.nfc.NfcAdapter
import android.nfc.Tag

import com.yubico.authenticator.MainActivity
import com.yubico.yubikit.android.transport.nfc.NfcConfiguration
import com.yubico.yubikit.android.transport.nfc.NfcDispatcher
import com.yubico.yubikit.android.transport.nfc.NfcReaderDispatcher

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

import org.slf4j.LoggerFactory

class NfcActivityDispatcher(private val coroutineScope: CoroutineScope) : NfcDispatcher {

    private lateinit var adapter: NfcAdapter
    private lateinit var yubikitNfcDispatcher: NfcReaderDispatcher

    private val logger = LoggerFactory.getLogger(NfcActivityDispatcher::class.java)

    override fun enable(
        activity: Activity,
        nfcConfiguration: NfcConfiguration,
        handler: NfcDispatcher.OnTagHandler
    ) {

        adapter = NfcAdapter.getDefaultAdapter(activity)
        yubikitNfcDispatcher = NfcReaderDispatcher(adapter)

        logger.info("enabling yubikit NFC activity dispatcher")
        yubikitNfcDispatcher.enable(
            activity,
            nfcConfiguration,
            TagInterceptor(activity as MainActivity, coroutineScope, handler)
        )

    }

    override fun disable(activity: Activity) {
        yubikitNfcDispatcher.disable(activity)
        logger.info("disabling yubikit NFC activity dispatcher")
    }

    class TagInterceptor(
        private val activity: MainActivity,
        private val coroutineScope: CoroutineScope,
        private val tagHandler: NfcDispatcher.OnTagHandler
    ) : NfcDispatcher.OnTagHandler {

        private val logger = LoggerFactory.getLogger(TagInterceptor::class.java)

        override fun onTag(tag: Tag) {
            coroutineScope.launch {
                activity.appMethodChannel.nfcActivityStateChanged(NfcActivityState.TAG_PRESENT)
                delay(500)
                activity.appMethodChannel.nfcActivityStateChanged(NfcActivityState.PROCESSING_STARTED)
                delay(500)
                logger.info("Calling original onTag")
                tagHandler.onTag(tag)
                delay(500)
                logger.info("Marking call as successful")
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