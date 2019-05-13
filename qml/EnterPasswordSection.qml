import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ColumnLayout {

    readonly property int dynamicWidth: 600
    readonly property int dynamicMargin: 64
    spacing: 20

    function clear() {
        passwordField.text = ""
        rememberPasswordCheckBox.checked = false
    }

    function validate() {
        yubiKey.validate(passwordField.text, rememberPasswordCheckBox.checked,
                         function (resp) {
                             if (resp.success) {
                                 yubiKey.calculateAll(navigator.goToCredentials)
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
            Layout.alignment: Qt.AlignHLeft | Qt.AlignVCenter

            StyledImage {
                id: lock
                Layout.alignment: parent.left | Qt.AlignVCenter
                Layout.topMargin: 20
                Layout.leftMargin: -11
                Layout.bottomMargin: 10
                iconWidth: 80
                source: "../images/lock.svg"
                color: app.isDark(
                           ) ? defaultLightForeground : defaultLightOverlay
            }

            Label {
                text: "Password required"
                Layout.rowSpan: 1
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                font.bold: true
                lineHeight: 1.5
                Layout.alignment: Qt.AlignHLeft | Qt.AlignVCenter
                color: formLabel
            }

            Label {
                text: "To prevent unauthorized access this YubiKey is protected with a password. Enter the password to continue."
                Layout.minimumWidth: 320
                Layout.maximumWidth: app.width - 64 < 600 ? app.width - 64 : 600
                Layout.rowSpan: 1
                lineHeight: 1.1
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                color: formText
            }
        }
        ColumnLayout {
            Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
            StyledTextField {
                id: passwordField
                labelText: qsTr("Password")
                echoMode: TextInput.Password
                Keys.onEnterPressed: validate()
                Keys.onReturnPressed: validate()
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
                    leftPadding: 0
                    indicator.width: 16
                    indicator.height: 16
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
