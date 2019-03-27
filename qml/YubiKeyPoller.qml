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
            // Polling to see what devices we have.
            yubiKey.refreshCcid()

            if (timeToCalculateAll() && yubiKey.loadedDevices) {
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
                entries.clear()
                entries.append(sortedEntries)
                updateNextCalculateAll()
            } else {
                console.log(resp.error_id)
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
