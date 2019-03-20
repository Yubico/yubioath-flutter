import QtQuick 2.9
import QtQuick.Controls 2.2
import "utils.js" as Utils

Timer {
    triggeredOnStart: true
    interval: 500
    repeat: true
    running: app.visible
    onTriggered: {
        if (entries.count === 0) {
            yubiKey.calculateAll(function (resp) {
                if (resp.success) {
                    entries.clear()
                    entries.append(resp.entries)
                } else {
                    entries.clear()
                    console.log(resp.error_id)
                }
            })
        } else {
            for (var i = 0; i < entries.count; i++) {
                if (!entries.get(i).touch && isExpired(entries.get(i))) {
                    yubiKey.calculate(entries.get(i), function (resp) {
                        if (resp.success) {
                            for (var i = 0; i < entries.count; i++) {
                                if (entries.get(
                                            i).credential.key === resp.credential.key) {
                                    entries.set(i, resp)
                                    entries.set(i, resp)
                                }
                            }
                        } else {
                            console.log(resp.error_id)
                        }
                    })
                }
            }
        }
    }

    function isExpired(entry) {
        return entry !== null && entry.code
                && (entry.credential.oath_type !== "HOTP")
                && (entry.code.valid_to - (Date.now() / 1000) <= 0)
    }
}
