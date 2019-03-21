import QtQuick 2.9
import QtQuick.Controls 2.2
import "utils.js" as Utils

Timer {

    // Timestamp in seconds for when it's time for the next calculateAll call.
    property int nextCalculateAll: 0

    triggeredOnStart: true
    interval: 500
    repeat: true
    running: app.visible
    onTriggered: refresh()

    function isExpired(entry) {
        return entry !== null && entry.code
                && (entry.credential.oath_type !== "HOTP")
                && (entry.code.valid_to - (Date.now() / 1000) <= 0)
    }

    function refresh() {
        if (timeToRefresh()) {
            calculateAll()
        }
    }

    function calculateAll() {
        yubiKey.calculateAll(function (resp) {
            if (resp.success) {
                var newEntries = resp.entries
                for (var i = 0; i < newEntries.length; i++) {
                    var entry = newEntries[i]
                    if (entries.hasEntry(entry)) {
                        entries.updateEntry(entry)
                    } else {
                        entries.addEntry(entry)
                    }
                    updateNextCalculateAll(entry)
                }
            } else {
                console.log(resp.error_id)
            }
        })
    }

    function updateNextCalculateAll(entry) {
        if (entry.code && entry.code.valid_to > nextCalculateAll
                && entry.credential.period === 30) {
            nextCalculateAll = entry.code.valid_to
        }
    }

    function timeToRefresh() {
        return nextCalculateAll <= Utils.getNow()
    }
}
