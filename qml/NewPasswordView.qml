import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Pane {
    objectName: 'newPasswordView'
    background: Rectangle {
        color: isDark() ? defaultDarkLighter : Material.background
    }
    padding: 50

    property string title: "Set password"

    function setPassword() {
        yubiKey.setPassword(newPasswordField.text, false, function (resp) {
            if (resp.success) {
                navigator.snackBar("Password set")
                navigator.pop()
            } else {
                navigator.snackBarError(resp.error_id)
                console.log(resp.error_id)
            }
        })
    }

    ColumnLayout {
        spacing: 20

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Image {
                id: lock
                sourceSize.width: 60
                Layout.alignment: parent.left | Qt.AlignVCenter
                Layout.topMargin: 20
                Layout.leftMargin: -11
                Layout.bottomMargin: 10
                fillMode: Image.PreserveAspectFit
                source: "../images/lock.svg"
                ColorOverlay {
                    source: lock
                    color: app.isDark(
                               ) ? app.defaultDarkOverlay : app.defaultLightOverlay
                    anchors.fill: lock
                }
            }
            Label {
                text: "Set a new password"
                Layout.rowSpan: 1
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                font.bold: true
                lineHeight: 1.5
                Layout.alignment: Qt.AlignHLeft | Qt.AlignVCenter
            }
            Label {
                text: "To prevent unauthorized access the YubiKey may be protected with a password."
                Layout.minimumWidth: 320
                Layout.maximumWidth: app.width - 100 < 600 ? app.width - 100 : 600
                Layout.rowSpan: 1
                lineHeight: 1.1
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            }
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
            TextField {
                id: newPasswordField
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.fillWidth: true
                placeholderText: qsTr("New Password")
                background.width: parent.width
                echoMode: TextInput.Password
                Keys.onEnterPressed: validate()
                Keys.onReturnPressed: validate()
                Material.accent: isDark() ? defaultLight : "#5f6368"
                selectedTextColor: isDark() ? defaultDark : defaultLight
                focus: true
            }
            TextField {
                id: confirmPasswordField
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.fillWidth: true
                placeholderText: qsTr("Confirm Password")
                background.width: parent.width
                echoMode: TextInput.Password
                Keys.onEnterPressed: validate()
                Keys.onReturnPressed: validate()
                Material.accent: isDark() ? defaultLight : "#5f6368"
                selectedTextColor: isDark() ? defaultDark : defaultLight
                focus: true
            }
            Item {
                id: item1
                Layout.fillHeight: false
                Layout.fillWidth: true


                /*
                CheckBox {
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    id: rememberPasswordCheckBox
                    text: "Remember password"
                    font.pixelSize: 12
                    anchors.left: parent.left
                    anchors.leftMargin: 1
                }*/
                StyledButton {
                    flat: true
                    text: "Cancel"
                    anchors.right: parent.right
                    anchors.rightMargin: 70
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    onClicked: navigator.pop()
                }
                StyledButton {
                    enabled: newPasswordField.text === confirmPasswordField.text
                    text: "Ok"
                    onClicked: setPassword()
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                }
            }
        }
    }
}
