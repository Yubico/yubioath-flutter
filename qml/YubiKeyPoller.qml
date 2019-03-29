import QtQuick 2.9
import QtQuick.Controls 2.2
import "utils.js" as Utils

Timer {

    // Timestamp in seconds for when it's time for the next calculateAll call.
    property int nextCalculateAll: 0

    triggeredOnStart: true
    interval: 1000
    repeat: true
    running: app.visible
    onTriggered: refresh()

    function isExpired(entry) {
        return entry !== null && entry.code
                && (entry.credential.oath_type !== "HOTP")
                && (entry.code.valid_to - (Date.now() / 1000) <= 0)
    }

    function refresh() {
        if (app.isInForeground) {
            // Polling to see what USB CCID devices we have.
            yubiKey.refreshDevices(function (resp) {
                if (resp.success) {
                    // If the stringified list of devices is
                    // exactly the same, probably nothing changed.
                    var oldDevices = JSON.stringify(yubiKey.availableDevices)
                    var newDevices = JSON.stringify(resp.devices)
                    if (oldDevices !== newDevices) {
                        // Something have changed, save the new devices
                        // and do a calculateAll, if there is still devices.
                        // TODO: Which device should we pick if there is several?
                        yubiKey.availableDevices = resp.devices
                        if (yubiKey.availableDevices.length > 0) {
                            navigator.goToCredentials()
                            calculateAll()
                        } else {
                            // All devices seem to have gone away, clear credentials.
                            navigator.goToNoYubiKeyView()
                            entries.clear()
                        }
                    }
                } else {
                    console.log("refresh failed:", resp.error_id)
                    yubiKey.availableDevices = []
                    entries.clear()
                }
            })

            if (timeToCalculateAll() && yubiKey.availableDevices.length > 0) {
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
        yubiKey.calculateAll(function (resp) {
            if (resp.success) {
                // Sort the raw entries, because it's not obvious how to
                // sort them when they are inside the ListModel.
                var sortedEntries = sortEntries(resp.entries)
                entries.updateEntries(sortedEntries)
                updateNextCalculateAll()
            } else {
                if (resp.error_id === 'access_denied') {
                    entries.clear()
                    navigator.goToEnterPassword()
                }
                console.log("calculateAll failed:", resp.error_id)
            }
        })
    }

    function updateNextCalculateAll() {
        // Next calculateAll should be when one a default TOTP cred expires.
        // TODO: This should probably expiration of the TOTP cred with the shortest period expires.
        for (var i = 0; i < entries.count; i++) {
            var entry = entries.get(i)
            if (entry.code && entry.code.valid_to > nextCalculateAll
                    && entry.credential.period === 30) {
                nextCalculateAll = entry.code.valid_to
            }
        }
    }

    function timeToCalculateAll() {
        return nextCalculateAll <= Utils.getNow()
    }
}
