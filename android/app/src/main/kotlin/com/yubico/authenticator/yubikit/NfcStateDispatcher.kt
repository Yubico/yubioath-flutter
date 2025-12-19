/*
 * Copyright (C) 2023-2024 Yubico.
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

package com.yubico.authenticator.yubikit

import android.app.Activity
import android.nfc.NfcAdapter
import com.yubico.yubikit.android.transport.nfc.NfcConfiguration
import com.yubico.yubikit.android.transport.nfc.NfcDispatcher
import com.yubico.yubikit.android.transport.nfc.NfcReaderDispatcher
import org.slf4j.LoggerFactory

interface NfcStateListener {
    fun onChange(newState: NfcState)
}

class NfcStateDispatcher(private val listener: NfcStateListener) : NfcDispatcher {

    private lateinit var adapter: NfcAdapter
    private lateinit var yubikitNfcDispatcher: NfcReaderDispatcher

    private val logger = LoggerFactory.getLogger(NfcStateDispatcher::class.java)

    override fun enable(
        activity: Activity,
        nfcConfiguration: NfcConfiguration,
        handler: NfcDispatcher.OnTagHandler
    ) {
        adapter = NfcAdapter.getDefaultAdapter(activity)
        yubikitNfcDispatcher = NfcReaderDispatcher(adapter)

        logger.debug("enabling yubikit NFC state dispatcher")
        yubikitNfcDispatcher.enable(
            activity,
            nfcConfiguration,
            handler
        )
    }

    override fun disable(activity: Activity) {
        listener.onChange(NfcState.DISABLED)
        yubikitNfcDispatcher.disable(activity)
        logger.debug("disabling yubikit NFC state dispatcher")
    }
}
