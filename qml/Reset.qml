import QtQuick 2.0
import QtQuick.Dialogs 1.2

MessageDialog {
    icon: StandardIcon.Critical
    title: qsTr("Reset OATH functionality")
    text: qsTr("This will delete all OATH credentials stored on the device, and reset the password. This action cannot be undone. Are you sure you want to reset the device?")
    standardButtons: StandardButton.Ok | StandardButton.Cancel
}
