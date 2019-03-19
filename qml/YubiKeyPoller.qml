import QtQuick 2.9
import QtQuick.Controls 2.2

Timer {
    triggeredOnStart: true
    interval: 5000
    repeat: true
    running: app.visible
    onTriggered: {
        yubiKey.calculateAll(function (resp) {
            if (resp.success) {
                console.log(JSON.stringify(resp.entries))
                app.entries = resp.entries
            } else {
                app.entries = []
                console.log(resp.error_id)
            }
        })
    }
}
