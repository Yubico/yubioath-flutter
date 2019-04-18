import QtQuick 2.9
import QtQuick.Controls 2.2
import "utils.js" as Utils

Timer {

    // Timestamp in seconds for when it's time for the next calculateAll call.
    // -1 means never
    property int nextCalculateAll: -1

    triggeredOnStart: true
    interval: 1000
    repeat: true
    running: app.visible
    onTriggered: refresh()

    function refresh() {
        if (app.isInForeground) {
            // Polling to see what devices we have.
            yubiKey.refreshDevices(settings.otpMode, function (resp) {
                if (resp.success) {
                    // If the stringified list of devices is
                    // exactly the same, nothing changed.
                    var oldDevices = JSON.stringify(yubiKey.availableDevices)
                    var newDevices = JSON.stringify(resp.devices)
                    if (oldDevices !== newDevices) {
                        // Something have changed, save the new devices
                        // and do a calculateAll, if there is still devices.
                        yubiKey.availableDevices = resp.devices
                        // For now we only show credentials if there is 1 device
                        if (yubiKey.availableDevices.length === 1) {
                            yubiKey.currentDevice = resp.devices[0]
                            navigator.goToCredentials()
                            calculateAll()
                        } else {
                            // No or too many devices, clear credentials,
                            // and stop any scheduled calculateAll calls.
                            navigator.goToNoYubiKeyView()
                            nextCalculateAll = -1
                            entries.clear()
                        }
                    }
                } else {
                    navigator.snackBarError(navigator.getErrorMessage(
                                                resp.error_id))
                    console.log("refresh failed:", resp.error_id)
                    yubiKey.currentDevice = null
                    yubiKey.availableDevices = []
                    entries.clear()
                }
            })

            if (timeToCalculateAll() && yubiKey.currentDevice
                    && !yubiKey.locked) {
                calculateAll()
            }
        }
    }

    function sortEntries(entries) {

        function getSortableName(credential) {
            return (credential.issuer
                    || '') + (credential.name
                              || '') + '/' + (credential.period || '')
        }

        return entries.sort(function (a, b) {
            return getSortableName(a.credential).localeCompare(
                        getSortableName(b.credential))
        })
    }

    function calculateAll() {

        if (settings.otpMode) {
            yubiKey.otpCalculateAll(function (resp) {
                if (resp.success) {
                    // No sorting needed, there can be maximum 2 slot entries.
                    entries.updateEntries(resp.entries)
                    updateNextCalculateAll()
                } else {
                    navigator.snackBarError(navigator.getErrorMessage(
                                                resp.error_id))
                    console.log("otpCalculateAll failed:", resp.error_id)
                }
            })
        } else {
            yubiKey.calculateAll(function (resp) {
                if (resp.success) {
                    // Sort the raw entries, because it's not obvious how to
                    // sort them when they are inside the ListModel.
                    var sortedEntries = sortEntries(resp.entries)
                    entries.updateEntries(resp.entries)
                    updateNextCalculateAll()
                } else {
                    if (resp.error_id === 'access_denied') {
                        entries.clear()
                        yubiKey.hasPassword = true
                        yubiKey.locked = true
                        navigator.goToEnterPassword()
                    } else {
                        navigator.snackBarError(navigator.getErrorMessage(
                                                    resp.error_id))
                        console.log("calculateAll failed:", resp.error_id)
                    }
                }
            })
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
}
