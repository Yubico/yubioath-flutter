import QtQuick 2.0
import io.thp.pyotherside 1.4


// @disable-check M300
Python {
    id: py

    property int nDevices
    property bool hasDevice
    property string name
    property string version
    property string serial
    property var features: []
    property var connections: []
    property var credentials: null
    property int nextRefresh: 0
    property var enabled: []
    property bool ready: false
    property var queue: []

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

    onError: {
        console.log('Python error: ' + traceback)
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

    function refresh() {
        do_call('yubikey.controller.count_devices', [], function (n) {
            nDevices = n
            if (nDevices == 1) {
                do_call('yubikey.controller.refresh', [], function (dev) {
                    hasDevice = dev !== undefined && dev !== null
                    name = dev ? dev.name : ''
                    version = dev ? dev.version : ''
                    serial = dev ? dev.serial : ''
                    enabled = dev ? dev.enabled : []
                    connections = dev ? dev.connections : []

                    var now = Math.floor(Date.now() / 1000)
                    if (nextRefresh < now) {
                        refreshCredentials()
                    }
                })
            } else if (hasDevice) {
                hasDevice = false
                credentials = null
                nextRefresh = 0
            }
        })
    }

    function refreshCredentials() {
        var now = Math.floor(Date.now() / 1000)
        if (enabled.indexOf('CCID') != -1) {
            do_call('yubikey.controller.refresh_credentials', [now],
                    handleCredentials)
        }
    }

    function calculate(credential) {
        var now = Math.floor(Date.now() / 1000)
        do_call('yubikey.controller.calculate', [credential, now],
                updateCredential)
    }

    function updateCredential(cred) {
        var result = []
        for (var i = 0; i < credentials.length; i++) {
            if (credentials[i].name === cred.name) {
                result.push(cred)
            } else {
                result.push(credentials[i])
            }
        }
        credentials = result
    }

    function handleCredentials(creds) {
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
            // TOTP credentials should be updated
            result.push(cred)
        }
        nextRefresh = minExpiration
        credentials = result
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

    function addCredential(name, key, oathType, digits, algorithm, touch) {
        do_call('yubikey.controller.add_credential',
                [name, key, oathType, digits, algorithm, touch])
    }

    function set_mode(connections, cb) {
        do_call('yubikey.controller.set_mode', [connections], cb)
    }
}
