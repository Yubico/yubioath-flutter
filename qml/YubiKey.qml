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
    property var enabled: []
    property bool ready: false
    property var queue: []

    Component.onCompleted: {
        importModule('site', function() {
            call('site.addsitedir', [appDir + '/pymodules'], function() {
                addImportPath(urlPrefix + '/py')
                importModule('yubikey', function () {
                    ready = true
                    do_call('yubikey.controller.get_features', [], function (res) {
                        features = res
                        for(var i in queue) {
                            do_call(queue[i][0], queue[i][1], queue[i][2])
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
            call(func, args, function(json) {
                if (cb) {
                    cb(json ? JSON.parse(json) : undefined)
                }
            })
        }
    }

    function getSortedFeatures() {
        var sortedFeatures = []
        if (features.indexOf('OTP') != -1) {
         sortedFeatures.push('OTP');
        }
        if (features.indexOf('PIV') != -1) {
         sortedFeatures.push('PIV');
        }
        if (features.indexOf('OATH') != -1) {
         sortedFeatures.push('OATH');
        }
        if (features.indexOf('OPGP') != -1) {
         sortedFeatures.push('OPGP');
        }
        if (features.indexOf('U2F') != -1) {
         sortedFeatures.push('U2F');
        }
        return sortedFeatures;
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
                })
            } else if (hasDevice) {
                hasDevice = false
            }
        })

    }

    function set_mode(connections, cb) {
        do_call('yubikey.controller.set_mode', [connections], cb)
    }

    function slots_status(cb) {
        do_call('yubikey.controller.slots_status', [], cb)
    }

    function erase_slot(slot, cb) {
        do_call('yubikey.controller.erase_slot', [slot], cb)
    }

    function swap_slots(cb) {
        do_call('yubikey.controller.swap_slots', [], cb)
    }

    function serial_modhex(cb) {
        do_call('yubikey.controller.serial_modhex', [], cb)
    }

    function random_uid(cb) {
        do_call('yubikey.controller.random_uid', [], cb)
    }

    function random_key(bytes, cb) {
        do_call('yubikey.controller.random_key', [bytes], cb)
    }

    function generate_static_pw(cb) {
        do_call('yubikey.controller.generate_static_pw', [], cb)
    }

    function program_otp(slot, public_id, private_id, key, cb) {
        do_call('yubikey.controller.program_otp', [slot, public_id, private_id, key], cb)
    }

    function program_challenge_response(slot, key, touch, cb) {
        do_call('yubikey.controller.program_challenge_response', [slot, key, touch], cb)
    }

    function program_static_password(slot, password, cb) {
        do_call('yubikey.controller.program_static_password', [slot, password], cb)
    }

    function program_oath_hotp(slot, key, digits, cb) {
        do_call('yubikey.controller.program_oath_hotp', [slot, key, digits], cb)
    }
}


