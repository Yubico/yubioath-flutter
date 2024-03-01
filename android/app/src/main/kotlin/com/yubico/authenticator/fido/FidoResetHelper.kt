/*
 * Copyright (C) 2024 Yubico.
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

package com.yubico.authenticator.fido

import com.yubico.authenticator.MainViewModel
import com.yubico.authenticator.NULL
import com.yubico.authenticator.device.DeviceManager
import com.yubico.authenticator.fido.data.Session
import com.yubico.authenticator.fido.data.YubiKitFidoSession
import com.yubico.yubikit.core.application.CommandState
import com.yubico.yubikit.core.fido.CtapException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.slf4j.LoggerFactory
import java.io.IOException
import java.util.Timer
import java.util.TimerTask
import java.util.concurrent.Executors
import kotlin.concurrent.schedule
import kotlin.coroutines.cancellation.CancellationException
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

enum class FidoResetState(val value: String) {
    Remove("remove"),
    Insert("insert"),
    Touch("touch")
}

class FidoResetHelper(
    private val deviceManager: DeviceManager,
    private val fidoViewModel: FidoViewModel,
    private val mainViewModel: MainViewModel,
    private val connectionHelper: FidoConnectionHelper,
    private val pinStore: FidoPinStore
) {

    var inProgress = false

    private val dispatcher = Executors.newSingleThreadExecutor().asCoroutineDispatcher()
    private val coroutineScope = CoroutineScope(SupervisorJob() + dispatcher)
    private var resetCommandState: CommandState? = null
    private var cancelReset: Boolean = false

    suspend fun reset(): String {
        try {
            deviceManager.clearDeviceInfoOnDisconnect = false
            inProgress = true
            fidoViewModel.updateResetState(FidoResetState.Remove)
            val usb = deviceManager.isUsbKeyConnected()
            if (usb) {
                resetOverUSB()
            } else {
                resetOverNfc()
            }
            logger.info("FIDO reset complete")
        } catch (e: CancellationException) {
            logger.debug("FIDO reset cancelled")
        } finally {
            inProgress = false
            deviceManager.clearDeviceInfoOnDisconnect = true
            if (!deviceManager.isUsbKeyConnected()) {
                fidoViewModel.setSessionState(null)
                fidoViewModel.updateCredentials(emptyList())
            }
        }
        return NULL
    }

    fun cancelReset(): String {
        cancelReset = true
        resetCommandState?.cancel()
        inProgress = false
        return NULL
    }

    private var cancellationTimer: TimerTask? = null
    fun onPause() {
        cancellationTimer?.cancel()
        cancellationTimer = Timer().schedule(300) {
            // the timer has not been cancelled at this point,
            // the application is in PAUSED state longer than 300ms
            // cancel ongoing reset
            cancelReset()
        }
    }

    fun onResume() {
        cancellationTimer?.cancel()
    }

    private suspend fun waitForUsbDisconnect() = suspendCoroutine { continuation ->
        coroutineScope.launch {
            cancelReset = false
            while (deviceManager.isUsbKeyConnected()) {
                if (cancelReset) {
                    logger.debug("Reset was cancelled while waiting for YubiKey to be disconnected")
                    continuation.resumeWithException(CancellationException())
                    return@launch
                }
                logger.debug("Waiting for YubiKey to be disconnected")
                delay(300)
            }
            continuation.resume(Unit)
        }
    }

    private suspend fun waitForConnection() = suspendCoroutine { continuation ->
        coroutineScope.launch {
            fidoViewModel.updateResetState(FidoResetState.Insert)
            while (!deviceManager.isUsbKeyConnected()) {
                if (cancelReset) {
                    // the key is not connected, clean device info
                    mainViewModel.setDeviceInfo(null)
                    continuation.resumeWithException(CancellationException())
                    return@launch
                }
                logger.debug("Waiting for YubiKey to be connected")
                delay(300)
            }
            continuation.resume(Unit)
        }
    }

    private suspend fun resetAfterTouch() = suspendCoroutine { continuation ->
        coroutineScope.launch(Dispatchers.Main) {
            fidoViewModel.updateResetState(FidoResetState.Touch)
            logger.debug("Waiting for touch")
            deviceManager.withKey { usbYubiKeyDevice ->
                connectionHelper.useSessionUsb(usbYubiKeyDevice) { fidoSession ->
                    resetCommandState = CommandState()
                    try {
                        doReset(fidoSession)
                        continuation.resume(Unit)
                    } catch (e: CtapException) {
                        when (e.ctapError) {
                            CtapException.ERR_KEEPALIVE_CANCEL -> {
                                logger.debug("Received ERR_KEEPALIVE_CANCEL during FIDO reset")
                            }

                            CtapException.ERR_ACTION_TIMEOUT -> {
                                logger.debug("Received ERR_ACTION_TIMEOUT during FIDO reset")
                            }

                            else -> {
                                logger.error("Received CtapException during FIDO reset: ", e)
                            }
                        }

                        continuation.resumeWithException(CancellationException())
                    } catch (e: IOException) {
                        // communication error, key was removed?
                        logger.error("IOException during FIDO reset: ", e)
                        // treat it as cancellation
                        continuation.resumeWithException(CancellationException())
                    } finally {
                        resetCommandState = null
                    }
                }
            }
        }
    }

    private suspend fun resetOverUSB() {
        waitForUsbDisconnect()
        waitForConnection()
        resetAfterTouch()
    }

    private suspend fun resetOverNfc() = suspendCoroutine { continuation ->
        coroutineScope.launch {
            fidoViewModel.updateResetState(FidoResetState.Touch)
            try {
                connectionHelper.useSessionNfc(FidoActionDescription.Reset) { fidoSession ->
                    doReset(fidoSession)
                    continuation.resume(Unit)
                }
            } catch (e: Throwable) {
                when (e) {
                    is CancellationException -> logger.debug("FIDO reset over NFC was cancelled")
                    else ->  logger.error("FIDO reset over NFC failed with exception: ", e)
                }
                // on NFC, clean device info in this situation
                mainViewModel.setDeviceInfo(null)
                continuation.resumeWithException(e)
            }
        }
    }

    private fun doReset(fidoSession: YubiKitFidoSession) {
        logger.debug("Calling FIDO reset")
        fidoSession.reset(resetCommandState)
        fidoViewModel.setSessionState(Session(fidoSession.info, true))
        fidoViewModel.updateCredentials(emptyList())
        pinStore.setPin(null)
    }

    companion object {
        private val logger = LoggerFactory.getLogger(FidoResetHelper::class.java)
    }
}