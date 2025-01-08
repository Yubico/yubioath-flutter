package com.yubico.authenticator

import com.yubico.authenticator.device.DeviceManager
import com.yubico.yubikit.core.YubiKeyDevice
import org.slf4j.LoggerFactory

class HomeContextManager(deviceManager: DeviceManager) : AppContextManager(deviceManager) {

    init {
        logger.debug("HomeContextManager initialized")
    }

    // previously connected device
    override fun activate() {
        super.activate()
        logger.debug("HomeContextManager activated")
    }

    override fun deactivate() {
        logger.debug("HomeContextManager deactivated")
        super.deactivate()
    }

    override suspend fun processYubiKey(device: YubiKeyDevice): Boolean {
        return true
    }

    override fun hasPending(): Boolean {
        return false
    }

    companion object {
        private val logger = LoggerFactory.getLogger(HomeContextManager::class.java)
    }
}