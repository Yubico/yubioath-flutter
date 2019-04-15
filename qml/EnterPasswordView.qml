import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Pane {
    id: pane
    objectName: 'enterPasswordView'
    padding: 50

    property string title: "Unlock YubiKey"

    function clear() {
        passwordField.text = ""
        rememberPasswordCheckBox.checked = false
    }

    function validate() {
        yubiKey.validate(passwordField.text, rememberPasswordCheckBox.checked,
                         function (resp) {
                             if (resp.success) {
                                 yubiKey.locked = false
                                 navigator.goToCredentials()
                             } else {
                                 clear()
                                 navigator.snackBarError(
                                             navigator.getErrorMessage(
                                                 resp.error_id))
                                 console.log("validate failed:", resp.error_id)
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
                               ) ? defaultLightForeground : app.defaultLightOverlay
                    anchors.fill: lock
                }
            }
            Label {
                text: "Password required"
                Layout.rowSpan: 1
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                font.bold: true
                lineHeight: 1.5
                Layout.alignment: Qt.AlignHLeft | Qt.AlignVCenter
            }
            Label {
                text: "To prevent unauthorized access this YubiKey is protected with a password. Enter the password to continue."
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
                id: passwordField
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.fillWidth: true
                placeholderText: qsTr("Password")
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
                CheckBox {
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    id: rememberPasswordCheckBox
                    font.pixelSize: 12
                    text: "Remember password"
                    anchors.left: parent.left
                    anchors.leftMargin: 1
                }
                StyledButton {
                    text: "Unlock"
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    onClicked: validate()
                }
            }
        }
    }
}
