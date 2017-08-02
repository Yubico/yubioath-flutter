import QtQuick 2.5
import io.thp.pyotherside 1.4


// @disable-check M300
Python {
    id: py

    property int nDevices
    property bool hasDevice
    property string name
    property string version
    property string oathId
    property var features: []
    property var connections: []
    property var credentials: []
    property int nextRefresh: 0
    property var enabled: []
    property bool ready: false
    property var queue: []
    property bool hasOTP: enabled.indexOf('OTP') !== -1
    property bool hasCCID: enabled.indexOf('CCID') !== -1
    property bool validated
    property bool slot1inUse
    property bool slot2inUse
    property var passwordKey
    property int expiration: 0
    signal wrongPassword
    signal credentialsRefreshed

    Component.onCompleted: {
        importModule('site', function () {
            call('site.addsitedir', [appDir + '/pymodules'], function () {
                addImportPath(urlPrefix + '/py')
                importModule('yubikey', function () {
                    ready = true
                    do_call('yubikey.controller.get_features', [],
                            function (res) {
                                features = res
                                for (var i in queue) {
                                    do_call(queue[i][0], queue[i][1],
                                            queue[i][2])
                                }
                                queue = []
                            })
                })
            })
        })
    }

    onHasDeviceChanged: {
        device.passwordKey = null
        device.validated = false
    }

    function do_call(func, args, cb) {
        if (!ready) {
            queue.push([func, args, cb])
        } else {
            call(func, args.map(JSON.stringify), function (json) {
                if (cb) {
                    cb(json ? JSON.parse(json) : undefined)
                }
            })
        }
    }

    function refresh(refreshCredentialsOnMode) {
        do_call('yubikey.controller.count_devices', [], function (n) {
            nDevices = n
            if (nDevices == 1) {
                do_call('yubikey.controller.refresh', [], function (dev) {
                    name = dev ? dev.name : ''
                    version = dev ? dev.version : ''
                    enabled = dev ? dev.enabled : []
                    connections = dev ? dev.connections : []
                    hasDevice = dev !== undefined && dev !== null
                })
            } else if (hasDevice) {
                hasDevice = false
                credentials = null
                nextRefresh = 0
            }
            refreshCredentialsOnMode()
        })
    }

    function refreshCCIDCredentials(force) {
        var now = Math.floor(Date.now() / 1000)
        if (force || (validated && nextRefresh <= now)) {
            do_call('yubikey.controller.refresh_credentials',
                    [now, passwordKey], updateAllCredentials)
        }
    }

    function refreshSlotCredentials(slots, digits, force) {
        var now = Math.floor(Date.now() / 1000)
        if (force || (nextRefresh <= now)) {
            do_call('yubikey.controller.refresh_slot_credentials',
                    [slots, digits, now], updateAllCredentials)
        }
    }

    function validate(providedPassword, cb) {
        do_call('yubikey.controller.derive_key', [providedPassword],
                function (key) {
                    validateFromKey(key, cb)
                })
    }

    function validateFromKey(key, cb) {
        do_call('yubikey.controller.validate', [key], function (res) {
            if (res !== false) {
                passwordKey = key
                validated = true
                if (cb != null) {
                    cb()
                }
            } else {
                wrongPassword()
            }
        })
    }

    function promptOrSkip(prompt) {

        do_call('yubikey.controller.get_oath_id', [], function (res) {

            oathId = res

            // Check if device id can be found in saved passwords
            // and validate with that key if found.
            var savedKey = getSavedKey(oathId)
            if (savedKey != null) {
                validateFromKey(savedKey, null)
                return
            }

            do_call('yubikey.controller.needs_validation', [], function (res) {
                if (res === true) {
                    prompt.open()
                }
                if (res === false) {
                    validated = true
                }
            })
        })
    }

    function getSavedKey(id) {
        // Read a saved password key, else return null.
        var entries = getPasswordEntries()
        return (entries[id] != null) ? entries[id] : null
    }

    function setPassword(password) {
        do_call('yubikey.controller.set_password', [password, passwordKey],
                function () {
                    if (password != null) {
                        validate(password, null)
                    }
                })
    }

    function updateAllCredentials(creds) {
        var result = []
        var minExpiration = (Date.now() / 1000) + 10000
        for (var i = 0; i < creds.length; i++) {
            var cred = creds[i]
            // Update min expiration
            if (cred.expiration && cred.expiration < minExpiration) {
                minExpiration = cred.expiration
            }
            // Touch credentials should only be replaced by user
            if (credentialExists(cred.name) && cred.touch) {
                result.push(getCredential(cred.name))
                continue
            }
            // HOTP credentials should only be replaced by user
            if (credentialExists(cred.name) && cred.oath_type === 'hotp') {
                result.push(getCredential(cred.name))
                continue
            }
            // The selected credential should still be selected,
            // with an updated code.
            if (selected != null) {
                if (selected.name === cred.name) {
                    selected = cred
                }
            }

            // TOTP credentials should be updated
            result.push(cred)
        }
        nextRefresh = minExpiration
        // Credentials is cleared so that
        // the view will refresh even if objects are the same
        credentials = []
        credentials = result
        updateExpiration()
        credentialsRefreshed()
    }

    function getCredential(name) {
        for (var i = 0; i < credentials.length; i++) {
            if (credentials[i].name === name) {
                return credentials[i]
            }
        }
    }

    function credentialExists(name) {
        if (credentials != null) {
            for (var i = 0; i < credentials.length; i++) {
                if (credentials[i].name === name) {
                    return true
                }
            }
        }
        return false
    }

    function hasAnyCredentials() {
        return credentials != null && credentials.length > 0
    }

    function updateExpiration() {
        var maxExpiration = 0
        if (credentials !== null) {
            for (var i = 0; i < credentials.length; i++) {
                var exp = credentials[i].expiration
                if (exp !== null && exp > maxExpiration) {
                    maxExpiration = exp
                }
            }
            expiration = maxExpiration
        }
    }

    function calculate(credential, copyAfterUpdate) {
        var now = Math.floor(Date.now() / 1000)
        do_call('yubikey.controller.calculate', [credential, now, passwordKey],
                function(cred) {
                    updateSingleCredential(cred, copyAfterUpdate)
                })
    }

    function calculateSlotMode(slot, digits, copyAfterUpdate) {
        var now = Math.floor(Date.now() / 1000)
        do_call('yubikey.controller.calculate_slot_mode', [slot, digits, now],
                function(cred) {
                    updateSingleCredential(cred, copyAfterUpdate)
                })
    }

    /**
      Put a credential coming from the YubiKey in the
      right position in the credential list.
      */
    function updateSingleCredential(cred, copyAfterUpdate) {
        var result = []
        for (var i = 0; i < credentials.length; i++) {
            if (credentials[i].name === cred.name) {
                result.push(cred)
            } else {
                result.push(credentials[i])
            }
        }
        credentials = result
        updateExpiration()
        credentialsRefreshed()
        // Update the selected credential
        // after update, since the code now
        // might be available.
        selected = cred
        if (copyAfterUpdate) {
            copy()
        }
    }

    function addCredential(name, key, oathType, digits, algorithm, touch, cb) {
        do_call('yubikey.controller.add_credential',
                [name, key, oathType, digits, algorithm, touch, passwordKey],
                cb)
    }

    function addSlotCredential(slot, key, touch, cb) {
        do_call('yubikey.controller.add_slot_credential',
                [slot, key, touch], cb)
    }

    function deleteCredential(credential) {
        do_call('yubikey.controller.delete_credential',
                [credential, passwordKey])
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
