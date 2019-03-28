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
                console.log(resp.error_id)
            }
        })
    }

    function refreshUsbCcidDevices(cb) {
        doCall('yubikey.controller.get_usb_ccid_devices', [], cb)
    }

    function refreshDescriptors(cb) {
        doCall('yubikey.controller.refresh_descriptors', [], cb)
    }

    function calculateAll(cb) {
        var now = Math.floor(Date.now() / 1000)
        doCall('yubikey.controller.calculate_all', [now], cb)
    }

    function calculate(credential, cb) {
        var margin = credential.touch ? 10 : 0
        var nowAndMargin = Utils.getNow() + margin
        doCall('yubikey.controller.calculate', [credential, nowAndMargin], cb)
    }

    function addCredential(name, key, issuer, oathType, algo, digits, period, touch, cb) {
        doCall('yubikey.controller.add_credential',
               [name, key, issuer, oathType, algo, digits, period, touch], cb)
    }

    function addSlotCredential(slot, key, touch, cb) {
        doCall('yubikey.controller.add_slot_credential', [slot, key, touch], cb)
    }

    function deleteCredential(credential, cb) {
        doCall('yubikey.controller.delete_credential', [credential], cb)
    }

    function deleteSlotCredential(slot) {
        doCall('yubikey.controller.delete_slot_credential', [slot])
    }

    function parseQr(screenShots, cb) {
        doCall('yubikey.controller.parse_qr', [screenShots], cb)
    }

    function reset() {
        doCall('yubikey.controller.reset', [])
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

    function validate(password, cb) {
        doCall('yubikey.controller.ccid_validate', [password], cb)
    }
}
