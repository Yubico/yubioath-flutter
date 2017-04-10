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

    onVisibilityChanged: {
        // Clear the password from old canceled entries
        // when a new dialog is shown.
        if (visible) {
            clear()
        }
    }

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
                KeyNavigation.tab: rememberPassword
                Keys.onEscapePressed: close()

            }
        }
        RowLayout {
            CheckBox {
                id: rememberPassword
                text: qsTr("Remember password")
                KeyNavigation.tab: okBtn
                Keys.onEscapePressed: close()
            }
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom
            Button {
                id: okBtn
                text: qsTr("Ok")
                Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                onClicked: promptAccepted()
                KeyNavigation.tab: cancelBtn
                Keys.onEscapePressed: close()
            }
            Button {
                text: qsTr("Cancel")
                id: cancelBtn
                onClicked: close()
                KeyNavigation.tab: password
                Keys.onEscapePressed: close()
            }
        }
    }

    function promptAccepted() {
        close()
        accepted()
    }

    function clear() {
        password.text = ''
        rememberPassword.checked = false
    }
}
