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
    property var connections: []
    property var entries: []
    property int nextRefresh: 0
    property var enabled: []
    property bool yubikeyReady: false
    property bool loggingModuleLoaded: false
    property bool loggingConfigured: false
    property bool yubikeyBusy: false
    property var queue: []
    property bool hasOTP: enabled.indexOf('OTP') !== -1
    property bool hasCCID: enabled.indexOf('CCID') !== -1
    property bool validated
    property bool slot1inUse
    property bool slot2inUse
    property int expiration: 0
    signal wrongPassword
    signal credentialsRefreshed
    signal enableLogging(string log_level, string log_file)
    signal disableLogging()

    Component.onCompleted: {
        importModule('ykman.logging_setup', function () {
            loggingModuleLoaded = true
        })
    }

    function loadYubikeyModule() {
        importModule('site', function () {
            call('site.addsitedir', [appDir + '/pymodules'], function () {
                addImportPath(urlPrefix + '/py')

                importModule('yubikey', function () {
                    yubikeyReady = true
                })
            })
        })
    }

    onHasDeviceChanged: {
        device.validated = false
    }

    onEnableLogging: {
        do_call('ykman.logging_setup.setup', [log_level || 'DEBUG', log_file || undefined], function() {
            loggingConfigured = true
        })
    }

    onDisableLogging: {
        loggingConfigured = true
    }

    onYubikeyReadyChanged: {
        runQueue()
    }

    onLoggingModuleLoadedChanged: {
        runQueue()
    }

    onLoggingConfiguredChanged: {
        loadYubikeyModule()
    }

    function isModuleLoaded(funcName) {
        if (funcName.startsWith("ykman.logging_setup.")) {
            return loggingModuleLoaded
        } else {
            return yubikeyReady
        }
    }

    function runQueue() {
        var oldQueue = queue
        queue = []
        for (var i in oldQueue) {
            do_call(oldQueue[i][0], oldQueue[i][1], oldQueue[i][2])
        }
    }

    function do_call(func, args, cb) {
        if (!isModuleLoaded(func)) {
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

    function refresh(slotMode, refreshCredentialsOnMode) {
        do_call('yubikey.controller.count_devices', [], function (n) {
            nDevices = n
            if (nDevices == 1) {
                do_call('yubikey.controller.refresh', [slotMode],
                        function (dev) {
                            name = dev ? dev.name : ''
                            version = dev ? dev.version : null
                            enabled = dev ? dev.enabled : []
                            connections = dev ? dev.connections : []
                            hasDevice = dev !== undefined && dev !== null
                        })
            } else if (hasDevice) {
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
            do_call('yubikey.controller.refresh_credentials', [now],
                    updateAllCredentials)
        }
    }

    function refreshSlotCredentials(slots, digits, force) {
        var now = Math.floor(Date.now() / 1000)
        if ((force || (nextRefresh <= now)) && !yubikeyBusy) {
            yubikeyBusy = true
            do_call('yubikey.controller.refresh_slot_credentials',
                    [slots, digits, now], updateAllCredentials)
        }
    }

    function validate(password, remember) {
        do_call('yubikey.controller.provide_password', [password, remember],
                function (res) {
                    if (res) {
                        validated = true
                    } else {
                        wrongPassword()
                    }
                })
    }

    function promptOrSkip(prompt) {
        do_call('yubikey.controller.needs_validation', [], function (res) {
            if (res === true) {
                prompt.open()
            } else {
                validated = true
            }
        })
    }

    function setPassword(password, remember) {
        do_call('yubikey.controller.set_password', [password, remember],
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

    function calculate(entry, copyAfterUpdate) {
        var now = Math.floor(Date.now() / 1000)
        var margin = entry.credential.touch ? 10 : 0
        do_call('yubikey.controller.calculate',
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
        do_call('yubikey.controller.calculate_slot_mode',
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
        do_call('yubikey.controller.add_credential',
                [name, key, issuer, oathType, algo, digits, period, touch], cb)
    }

    function addSlotCredential(slot, key, touch, cb) {
        do_call('yubikey.controller.add_slot_credential',
                [slot, key, touch], cb)
    }

    function deleteCredential(credential) {
        do_call('yubikey.controller.delete_credential', [credential])
    }

    function deleteSlotCredential(slot) {
        do_call('yubikey.controller.delete_slot_credential', [slot])
    }

    function parseQr(screenShots, cb) {
        do_call('yubikey.controller.parse_qr', [screenShots], cb)
    }

    function reset() {
        do_call('yubikey.controller.reset', [])
    }

    function getSlotStatus(cb) {
        do_call('yubikey.controller.slot_status', [], function (res) {
            slot1inUse = res[0]
            slot2inUse = res[1]
            cb()
        })
    }
}
