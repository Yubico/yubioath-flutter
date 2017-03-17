import QtQuick 2.0
import QtQuick.Dialogs 1.2

MessageDialog {
    icon: StandardIcon.Information
    title: qsTr("Password set")
    text: qsTr("A new password has been set.")
    standardButtons: StandardButton.Ok
}
