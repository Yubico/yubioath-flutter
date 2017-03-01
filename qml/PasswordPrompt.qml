import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2

Dialog {
    id: passwordPrompt
    title: qsTr("Enter password")
    standardButtons: StandardButton.Ok | StandardButton.Cancel

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
                Layout.fillWidth: true
            }
        }
        RowLayout {
            CheckBox {
                id: rememberPassword
                text: qsTr("Remember password")
            }
        }
    }
}
