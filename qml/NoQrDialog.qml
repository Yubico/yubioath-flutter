import QtQuick 2.5
import QtQuick.Dialogs 1.2

MessageDialog {
    id: noQr
    icon: StandardIcon.Warning
    title: qsTr("No QR code found")
    text: qsTr("Could not find a QR code. Make sure the QR code is fully visible on the screen.")
    standardButtons: StandardButton.Ok
}
