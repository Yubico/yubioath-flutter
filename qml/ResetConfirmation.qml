import QtQuick 2.0
import QtQuick.Dialogs 1.2

MessageDialog {
    icon: StandardIcon.Information
    title: qsTr("Device has been reset")
    text: qsTr("The device has now been reset.")
    standardButtons: StandardButton.Ok
}
