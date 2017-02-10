import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2

Dialog {
    id: passwordPrompt
    title: qsTr("Set new password")
    standardButtons: StandardButton.NoButton

    ColumnLayout {
        anchors.fill: parent

        GridLayout {
            columns: 2
            Label {
                text: qsTr("New password (blank for none): ")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.fillWidth: false
            }
            TextField {
                id: newPassword
                echoMode: TextInput.Password
                Layout.fillWidth: true
            }
            Label {
                text: qsTr("Confirm password: ")
            }
            TextField {
                id: confirmPassword
                echoMode: TextInput.Password
                Layout.fillWidth: true
            }
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom
            Button {
                text: qsTr("Set password")
                Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                onClicked: verifyMatching()
            }
            Button {
                text: qsTr("Cancel")
                enabled: true
                isDefault: true
                onClicked: close()
            }
        }
    }

    MessageDialog {
        id: noMatch
        icon: StandardIcon.Critical
        title: qsTr("Passwords does not match")
        text: qsTr("Password confirmation does not match password.")
        standardButtons: StandardButton.Ok
    }

    function verifyMatching() {
        if (newPassword.text !== confirmPassword.text) {
            noMatch.open()
        } else {
            close()
        }
    }
}
