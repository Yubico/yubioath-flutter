package com.yubico.authenticator

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter

class QRScannerCameraClosedBR(private val yubiKitController: YubikitController) : BroadcastReceiver()  {
    companion object {
        val intentFilter = IntentFilter("com.yubico.authenticator.QRScannerView.CameraClosed")
    }

    override fun onReceive(context: Context?, intent: Intent?) {

        val mainActivity = context as? MainActivity
        mainActivity?.let {
            yubiKitController.startNfcDiscovery(mainActivity) {}
        }
    }
}