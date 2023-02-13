package com.yubico.authenticator

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter

/** We observed that some devices (Pixel 2, OnePlus 6) automatically end NFC discovery
 * during the use of device camera when scanning QR codes. To handle NFC events correctly,
 * this receiver restarts the YubiKit NFC discovery when the QR Scanner camera is closed.
 */
class QRScannerCameraClosedBR(private val yubiKitController: YubikitController) :
    BroadcastReceiver() {
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