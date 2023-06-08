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

interface NfcActivityListener {
    fun onChange(newState: NfcActivityState)
}

class NfcActivityDispatcher(private val listener: NfcActivityListener) : NfcDispatcher {

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
            TagInterceptor(listener, handler)
        )
        listener.onChange(NfcActivityState.READY)

    }

    override fun disable(activity: Activity) {
        listener.onChange(NfcActivityState.NOT_ACTIVE)
        yubikitNfcDispatcher.disable(activity)
        logger.info("disabling yubikit NFC activity dispatcher")
    }

    class TagInterceptor(
        private val listener: NfcActivityListener,
        private val tagHandler: NfcDispatcher.OnTagHandler
    ) : NfcDispatcher.OnTagHandler {

        private val logger = LoggerFactory.getLogger(TagInterceptor::class.java)

        override fun onTag(tag: Tag) {
            listener.onChange(NfcActivityState.PROCESSING_STARTED)
            logger.debug("forwarding tag")
            tagHandler.onTag(tag)
        }

    }
}