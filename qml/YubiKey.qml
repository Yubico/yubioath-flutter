import QtQuick 2.5
import io.thp.pyotherside 1.4
import "utils.js" as Utils

// @disable-check M300
Python {
    id: py

    property bool yubikeyModuleLoaded: false
    property bool yubikeyReady: false
    property var queue: []

    property var availableDevices: []

    property var currentDevice
    property bool currentDeviceHasPassword: false
    property bool currentDeviceValidated: true

    signal enableLogging(string logLevel, string logFile)
    signal disableLogging

    // Timestamp in seconds for when it's time for the
    // next calculateAll call. -1 means never
    property int nextCalculateAll: -1

    Component.onCompleted: {
        importModule('site', function () {
            call('site.addsitedir', [appDir + '/pymodules'], function () {
                addImportPath(urlPrefix + '/py')
                importModule('yubikey', function () {
                    yubikeyModuleLoaded = true
                })
            })
        })
    }

    onEnableLogging: {
        doCall('yubikey.init_with_logging',
               [logLevel || 'DEBUG', logFile || null], function () {
                   yubikeyReady = true
               })
    }

    onDisableLogging: {
        doCall('yubikey.init', [], function () {
            yubikeyReady = true
        })
    }

    onYubikeyModuleLoadedChanged: runQueue()
    onYubikeyReadyChanged: runQueue()

    function isPythonReady(funcName) {
        if (funcName.startsWith("yubikey.init")) {
            return yubikeyModuleLoaded
        } else {
            return yubikeyReady
        }
    }

    function runQueue() {
        var oldQueue = queue
        queue = []
        for (var i in oldQueue) {
            doCall(oldQueue[i][0], oldQueue[i][1], oldQueue[i][2])
        }
    }

    function doCall(func, args, cb) {
        if (!isPythonReady(func)) {
            queue.push([func, args, cb])
        } else {
            call(func, args.map(JSON.stringify), function (json) {
                if (cb) {
                    try {
                        cb(json ? JSON.parse(json) : undefined)
                    } catch (err) {
                        console.log(err, json)
                    }
                }
            })
        }
    }

    function refresh() {
        if (app.isInForeground) {
            // Polling to see what devices we have.
            refreshDevices(settings.otpMode, function (resp) {
                if (resp.success) {
                    // If the stringified list of devices is
                    // exactly the same, nothing changed.
                    var oldDevices = JSON.stringify(availableDevices)
                    var newDevices = JSON.stringify(resp.devices)
                    if (oldDevices !== newDevices) {
                        // Something have changed, save the new devices
                        // and do a calculateAll, if there is still devices.
                        availableDevices = resp.devices
                        // For now we only show credentials if there is 1 device
                        if (availableDevices.length === 1) {
                            currentDevice = resp.devices[0]
                            calculateAll(navigator.goToCredentialsIfNotInSettings)
                        } else {
                            // No or too many devices, clear credentials,
                            // clear current device,
                            // and stop any scheduled calculateAll calls.
                            currentDevice = null
                            nextCalculateAll = -1
                            entries.clear()
                            navigator.goToCredentialsIfNotInSettings()
                            currentDeviceValidated = true
                        }
                    }
                } else {
                    navigator.snackBarError(navigator.getErrorMessage(
                                                resp.error_id))
                    console.log("refresh failed:", resp.error_id)
                    currentDevice = null
                    availableDevices = []
                    entries.clear()
                }
            })
            if (timeToCalculateAll() && !!currentDevice
                    && currentDeviceValidated) {
                calculateAll()
            }
        }
    }

    function calculateAll(cb) {

        function callback(resp) {
            if (resp.success) {
                entries.updateEntries(resp.entries)
                updateNextCalculateAll()
                currentDeviceValidated = true
            } else {
                if (resp.error_id === 'access_denied') {
                    entries.clear()
                    currentDeviceHasPassword = true
                    currentDeviceValidated = false
                    cb = navigator.goToEnterPasswordIfNotInSettings
                } else {
                    navigator.snackBarError(navigator.getErrorMessage(
                                                resp.error_id))
                    console.log("calculateAll failed:", resp.error_id)
                }
            }
            if (cb) {
                cb()
            }
        }

        if (settings.otpMode) {
            otpCalculateAll(callback)
        } else {
            ccidCalculateAll(callback)
        }
    }

    function updateNextCalculateAll() {
        // Next calculateAll should be when a default TOTP cred expires.
        for (var i = 0; i < entries.count; i++) {
            var entry = entries.get(i)
            if (entry.code && entry.credential.period === 30) {
                // Just use the first default one
                nextCalculateAll = entry.code.valid_to
                return
            }
        }
        // No default TOTP cred found, don't set a time for nextCalculateAll
        nextCalculateAll = -1
    }

    function timeToCalculateAll() {
        return nextCalculateAll !== -1 && nextCalculateAll <= Utils.getNow()
    }

    function supportsTouchCredentials() {
        return !!currentDevice && parseInt(currentDevice.version.join(
                                               "")) >= 426
    }

    function supportsOathSha512() {
        // TODO: FIPS keys also does not support this
        return !!currentDevice && parseInt(currentDevice.version.join(
                                               "")) >= 431
    }

    function scanQr(toastIfError) {
        navigator.goToLoading()
        parseQr(ScreenShot.capture(), function (resp) {
            if (resp.success) {
                navigator.goToNewCredentialAuto(resp)
                navigator.snackBar("QR code found on screen")
            } else {
                if (toastIfError) {
                    navigator.snackBarError(navigator.getErrorMessage(
                                                resp.error_id))
                }
                navigator.goToNewCredentialManual()
            }
        })
    }

    function ccidCalculateAll(cb) {
        var now = Math.floor(Date.now() / 1000)
        doCall('yubikey.controller.ccid_calculate_all', [now], cb)
    }

    function otpCalculateAll(cb) {
        var now = Utils.getNow()
        doCall('yubikey.controller.otp_calculate_all',
               [settings.slot1digits, settings.slot2digits, now], cb)
    }

    function refreshDevices(otpMode, cb) {
        doCall('yubikey.controller.refresh_devices', [otpMode], cb)
    }

    function calculate(credential, cb) {
        var margin = credential.touch ? 10 : 0
        var nowAndMargin = Utils.getNow() + margin
        doCall('yubikey.controller.ccid_calculate',
               [credential, nowAndMargin], cb)
    }

    function otpCalculate(credential, cb) {
        var margin = credential.touch ? 10 : 0
        var nowAndMargin = Utils.getNow() + margin
        var slot = (credential.key === "Slot 1") ? 1 : 2
        var digits = (slot === 1) ? settings.slot1digits : settings.slot2digits
        doCall('yubikey.controller.otp_calculate',
               [slot, digits, credential, nowAndMargin], cb)
    }

    function otpDeleteCredential(credential, cb) {
        var slot = (credential.key === "Slot 1") ? 1 : 2
        doCall('yubikey.controller.otp_delete_credential', [slot], cb)
    }

    function otpAddCredential(slot, key, touch, cb) {
        doCall('yubikey.controller.otp_add_credential', [slot, key, touch], cb)
    }

    function ccidAddCredential(name, key, issuer, oathType, algo, digits, period, touch, cb) {
        doCall('yubikey.controller.ccid_add_credential',
               [name, key, issuer, oathType, algo, digits, period, touch], cb)
    }

    function deleteCredential(credential, cb) {
        doCall('yubikey.controller.ccid_delete_credential', [credential], cb)
    }

    function parseQr(screenShots, cb) {
        doCall('yubikey.controller.parse_qr', [screenShots], cb)
    }

    function reset(cb) {
        doCall('yubikey.controller.ccid_reset', [], cb)
    }

    function otpSlotStatus(cb) {
        doCall('yubikey.controller.otp_slot_status', [], cb)
    }

    function clearKey() {
        doCall('yubikey.controller.clear_key', [])
    }

    function setPassword(password, remember, cb) {
        doCall('yubikey.controller.ccid_set_password', [password, remember], cb)
    }

    function validate(password, remember, cb) {
        doCall('yubikey.controller.ccid_validate', [password, remember], cb)
    }
}
