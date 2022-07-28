package com.yubico.authenticator

class NfcDiscoveryHelper(private val mainActivity: MainActivity) {
    private fun startDiscovery() {
        mainActivity.startNfcDiscovery()
    }

    private fun stopDiscovery() {
        mainActivity.stopNfcDiscovery()
    }

    fun restartDiscovery() {
        stopDiscovery()
        startDiscovery()
    }
}