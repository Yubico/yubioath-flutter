import QtQuick 2.5
import io.thp.pyotherside 1.4
import "utils.js" as Utils


// @disable-check M300
Python {

    id: py
    property int nDevices
    property bool hasDevice
    property string name
    property var version
    property string oathId
    property var supportedUsbInterfaces: []
    property var enabledUsbInterfaces: []
    property var entries: null
    property int nextRefresh: 0
    property bool yubikeyModuleLoaded: false
    property bool yubikeyReady: false
    property bool yubikeyBusy: false
    property var queue: []
    readonly property bool hasOTP: enabledUsbInterfaces.indexOf('OTP') !== -1
    readonly property bool hasCCID: enabledUsbInterfaces.indexOf('CCID') !== -1
    property bool validated
    property bool slot1inUse
    property bool slot2inUse
    property int expiration: 0
    signal wrongPassword
    signal credentialsRefreshed
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

    onHasDeviceChanged: {
        clearKey()
        device.validated = false
    }

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

    function calculateAll(cb) {
        var now = Math.floor(Date.now() / 1000)
        doCall('yubikey.controller.calculate_all', [now], cb)
    }

    function calculate(entry, cb) {
        var margin = entry.credential.touch ? 10 : 0
        var nowAndMargin = Utils.getNow() + margin
        doCall('yubikey.controller.calculate',
               [entry.credential, nowAndMargin], cb)
    }

    function addCredential(name, key, issuer, oathType, algo, digits, period, touch, cb) {
        doCall('yubikey.controller.add_credential',
               [name, key, issuer, oathType, algo, digits, period, touch], cb)
    }

    function addSlotCredential(slot, key, touch, cb) {
        doCall('yubikey.controller.add_slot_credential', [slot, key, touch], cb)
    }

    function deleteCredential(credential) {
        doCall('yubikey.controller.delete_credential', [credential])
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
}
