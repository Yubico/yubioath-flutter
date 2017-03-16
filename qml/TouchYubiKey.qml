import QtQuick 2.5
import QtQuick.Dialogs 1.2

MessageDialog {
    icon: StandardIcon.Information
    title: qsTr("Touch your YubiKey")
    text: qsTr("Touch your YubiKey to generate the code.")
    standardButtons: StandardButton.NoButton
}
