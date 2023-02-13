package com.yubico.authenticator

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.nfc.NfcAdapter
import com.yubico.authenticator.logging.Log

class NfcAdapterStateChangeBR(private val appMethodChannel: MainActivity.AppMethodChannel) : BroadcastReceiver() {
    companion object {
        val intentFilter = IntentFilter("android.nfc.action.ADAPTER_STATE_CHANGED")
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        intent?.let {
            val state = it.getIntExtra("android.nfc.extra.ADAPTER_STATE", 0)
            Log.d(MainActivity.TAG, "NfcAdapter state changed to $state")
            if (state == NfcAdapter.STATE_ON || state == NfcAdapter.STATE_TURNING_OFF) {
               appMethodChannel.nfcAdapterStateChanged(state == NfcAdapter.STATE_ON)
            }
        }

    }
}