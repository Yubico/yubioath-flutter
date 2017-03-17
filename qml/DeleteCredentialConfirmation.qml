import QtQuick 2.5
import QtQuick.Dialogs 1.2

MessageDialog {
    icon: StandardIcon.Warning
    title: qsTr("Delete credential?")
    text: qsTr("Are you sure you want to delete this credential?")
    standardButtons: StandardButton.Ok | StandardButton.Cancel
}
