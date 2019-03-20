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

    function refresh(slotMode, refreshCredentialsOnMode) {
        doCall('yubikey.controller.count_devices', [], function (n) {
            nDevices = n
            console.log('HERE')
            if (nDevices == 1) {
                doCall('yubikey.controller.refresh', [slotMode],
                       function (dev) {
                           var usable = dev && dev.usable
                           name = usable ? dev.name : ''
                           version = usable ? dev.version : null
                           enabledUsbInterfaces = usable ? dev.usb_interfaces_enabled : []
                           supportedUsbInterfaces = usable ? dev.usb_interfaces_supported : []
                           hasDevice = !!usable
                       })
            } else {
                // No longer has device
                hasDevice = false
                entries = null
                nextRefresh = 0
            }
            refreshCredentialsOnMode()
        })
    }

    function refreshCCIDCredentials(force) {
        var now = Math.floor(Date.now() / 1000)
        if ((force || (validated && nextRefresh <= now)) && !yubikeyBusy) {
            yubikeyBusy = true
            doCall('yubikey.controller.refresh_credentials', [now],
                   updateAllCredentials)
        }
    }

    function refreshSlotCredentials(slots, digits, force) {
        var now = Math.floor(Date.now() / 1000)
        if ((force || (nextRefresh <= now)) && !yubikeyBusy) {
            yubikeyBusy = true
            doCall('yubikey.controller.refresh_slot_credentials',
                   [slots, digits, now], updateAllCredentials)
        }
    }

    function validate(password, remember) {
        doCall('yubikey.controller.provide_password', [password, remember],
               function (res) {
                   if (res) {
                       validated = true
                   } else {
                       wrongPassword()
                   }
               })
    }

    function promptOrSkip(prompt) {
        doCall('yubikey.controller.needs_validation', [], function (res) {
            if (res === true) {
                prompt.open()
            } else {
                validated = true
            }
        })
    }

    function setPassword(password, remember) {
        doCall('yubikey.controller.set_password', [password, remember],
               function () {
                   validated = true
               })
    }

    function updateAllCredentials(newEntries) {
        device.yubikeyBusy = false
        var result = []
        var minExpiration = (Date.now() / 1000) + 60
        for (var i = 0; i < newEntries.length; i++) {
            var entry = newEntries[i]
            // Update min expiration
            if (entry.code && entry.code.valid_to < minExpiration
                    && entry.credential.period === 30) {
                minExpiration = entry.code.valid_to
            }
            // Touch credentials should only be replaced by user
            if (credentialExists(entry.credential.key)
                    && entry.credential.touch) {
                result.push(getEntry(entry.credential.key))
                continue
            }
            // HOTP credentials should only be replaced by user
            if (credentialExists(entry.credential.key)
                    && entry.credential.oath_type === 'HOTP') {
                result.push(getEntry(entry.credential.key))
                continue
            }
            // The selected credential should still be selected,
            // with an updated code.
            if (getSelected() != null) {
                if (getSelected().credential.key === entry.credential.key) {
                    selectCredential(entry)
                }
            }

            // TOTP credentials should be updated
            result.push(entry)
        }
        nextRefresh = minExpiration
        // Credentials is cleared so that
        // the view will refresh even if objects are the same
        entries = result
        entries.sort(function (a, b) {
            return getSortableName(a.credential).localeCompare(
                        getSortableName(b.credential))
        })

        updateExpiration()
        credentialsRefreshed()
    }

    function getSortableName(credential) {
        return (credential.issuer
                || '') + (credential.name
                          || '') + '/' + (credential.period || '')
    }

    function getEntry(key) {
        for (var i = 0; i < entries.length; i++) {
            if (entries[i].credential.key === key) {
                return entries[i]
            }
        }
    }

    function credentialExists(key) {
        if (entries != null) {
            for (var i = 0; i < entries.length; i++) {
                if (entries[i].credential.key === key) {
                    return true
                }
            }
        }
        return false
    }

    function hasAnyNonTouchTotpCredential() {
        return Utils.find(entries, function (entry) {
            return !entry.credential.touch
                    && entry.credential.oath_type === 'TOTP'
        }) || false
    }

    function hasAnyCredentials() {
        return entries != null && entries.length > 0
    }

    function updateExpiration() {
        var maxExpiration = 0
        if (entries !== null) {
            for (var i = 0; i < entries.length; i++) {
                if (entries[i].credential.period === 30) {
                    var exp = entries[i].code && entries[i].code.valid_to
                    if (exp !== null && exp > maxExpiration) {
                        maxExpiration = exp
                    }
                }
            }
            expiration = maxExpiration
        }
    }

    function _calculate(entry, copyAfterUpdate) {
        var now = Math.floor(Date.now() / 1000)
        var margin = entry.credential.touch ? 10 : 0
        doCall('yubikey.controller.calculate',
               [entry.credential, now + margin], function (code) {
                   if (code) {
                       updateSingleCredential(entry.credential, code,
                                              copyAfterUpdate)
                   } else {
                       touchYourYubikey.close()
                   }
               })
    }

    function calculateSlotMode(slot, digits, copyAfterUpdate, touch) {
        var now = Math.floor(Date.now() / 1000)
        var margin = touch ? 10 : 0
        doCall('yubikey.controller.calculate_slot_mode',
               [slot, digits, now + margin], function (entry) {
                   if (entry) {
                       updateSingleCredential(entry.credential, entry.code,
                                              copyAfterUpdate)
                   } else {
                       touchYourYubikey.close()
                   }
               })
    }

    /**
      Put a credential coming from the YubiKey in the
      right position in the credential list.
      */
    function updateSingleCredential(cred, code, copyAfterUpdate) {
        var entry = null
        for (var i = 0; i < entries.length; i++) {
            if (entries[i].credential.key === cred.key) {
                entry = entries[i]
                entry.code = code
            }
        }
        if (!cred.touch) {
            updateExpiration()
        }
        credentialsRefreshed()
        // Update the selected credential
        // after update, since the code now
        // might be available.
        selectCredential(entry)
        if (copyAfterUpdate) {
            copy()
        }
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
