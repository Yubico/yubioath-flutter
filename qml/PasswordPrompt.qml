import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2

DefaultDialog {
    id: passwordPrompt
    title: qsTr("Enter password")

    property string password: password.text
    property bool remember: rememberPassword.checked

    ColumnLayout {
        RowLayout {
            Label {
                text: qsTr("Password: ")
            }
            TextField {
                id: password
                echoMode: TextInput.Password
                focus: true
                Layout.fillWidth: true
                onAccepted: promptAccepted()
            }
        }
        RowLayout {
            CheckBox {
                id: rememberPassword
                text: qsTr("Remember password")
            }
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom
            Button {
                text: qsTr("Ok")
                Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                onClicked: promptAccepted()
            }
            Button {
                text: qsTr("Cancel")
                onClicked: close()
            }
        }
    }

    function promptAccepted() {
        close()
        accepted()
    }

    function clear() {
        password.text = ''
    }
}
