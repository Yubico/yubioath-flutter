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
    property var credentials: []
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
            call(func, args, function (json) {
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
                    credentials = dev ? dev.credentials : []
                })
            } else if (hasDevice) {
                hasDevice = false
            }
        })
    }

    function refresh_credentials() {
        if (enabled.indexOf('CCID') != -1) {
            do_call('yubikey.controller.refresh_credentials', [],
                    function (dev) {
                        credentials = dev ? dev.credentials : []
                    })
        }
    }

    function set_mode(connections, cb) {
        do_call('yubikey.controller.set_mode', [connections], cb)
    }
}
