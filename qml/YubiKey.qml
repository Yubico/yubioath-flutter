import QtQuick 2.5
import io.thp.pyotherside 1.4
import "utils.js" as Utils

// @disable-check M300
Python {
    id: py

    property bool yubikeyModuleLoaded: false
    property bool yubikeyReady: false
    property var queue: []

    property bool hasPassword: false
    property bool locked: false

    property var availableDevices: []
    property var currentDevice
    signal enableLogging(string logLevel, string logFile)
    signal disableLogging

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
        if (Utils.startsWith(funcName, "yubikey.init")) {
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

    function scanQr() {
        parseQr(ScreenShot.capture(), function (resp) {
            if (resp.success) {
                navigator.goToNewCredentialAuto(resp)
            } else {
                navigator.snackBarError(navigator.getErrorMessage(
                                            resp.error_id))
                console.log("scanQr failed:", resp.error_id)
            }
        })
    }

    function refreshDevices(otpMode, cb) {
        doCall('yubikey.controller.refresh_devices', [otpMode], cb)
    }

    function calculateAll(cb) {
        var now = Math.floor(Date.now() / 1000)
        doCall('yubikey.controller.ccid_calculate_all', [now], cb)
    }

    function calculate(credential, cb) {
        var margin = credential.touch ? 10 : 0
        var nowAndMargin = Utils.getNow() + margin
        doCall('yubikey.controller.ccid_calculate',
               [credential, nowAndMargin], cb)
    }

    function otpCalculateAll(cb) {
        var now = Utils.getNow()
        // TODO: use settings here
        doCall('yubikey.controller.otp_calculate_all',
               [true, 6, false, 6, now], cb)
    }

    function addCredential(name, key, issuer, oathType, algo, digits, period, touch, cb) {
        doCall('yubikey.controller.ccid_add_credential',
               [name, key, issuer, oathType, algo, digits, period, touch], cb)
    }

    function addSlotCredential(slot, key, touch, cb) {
        doCall('yubikey.controller.add_slot_credential', [slot, key, touch], cb)
    }

    function deleteCredential(credential, cb) {
        doCall('yubikey.controller.ccid_delete_credential', [credential], cb)
    }

    function deleteSlotCredential(slot) {
        doCall('yubikey.controller.delete_slot_credential', [slot])
    }

    function parseQr(screenShots, cb) {
        doCall('yubikey.controller.parse_qr', [screenShots], cb)
    }

    function reset(cb) {
        doCall('yubikey.controller.ccid_reset', [], cb)
    }

    function clearKey() {
        doCall('yubikey.controller.clear_key', [])
    }

    function getSlotStatus(cb) {
        doCall('yubikey.controller.slot_status', [], function (res) {
            slot1inUse = res[0]
            slot2inUse = res[1]
            cb()
        })
    }

    function setPassword(password, remember, cb) {
        doCall('yubikey.controller.ccid_set_password', [password, remember], cb)
    }

    function validate(password, remember, cb) {
        doCall('yubikey.controller.ccid_validate', [password, remember], cb)
    }
}
