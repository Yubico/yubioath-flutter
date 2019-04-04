import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Pane {
    objectName: 'newPasswordView'

    property string title: "Set password"

    function setPassword() {
        yubiKey.setPassword(newPasswordField.text,
                            rememberPasswordCheckBox.checked, function (resp) {
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
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        ColumnLayout {
            spacing: 20
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Image {
                    id: lock
                    sourceSize.height: 60
                    sourceSize.width: 100
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
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
                    background.width: width
                    echoMode: TextInput.Password
                }
                TextField {
                    id: confirmPasswordField
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    Layout.fillWidth: true
                    placeholderText: qsTr("Confirm Password")
                    background.width: width
                    echoMode: TextInput.Password
                }
                CheckBox {
                    id: rememberPasswordCheckBox
                    text: "Remember password"
                }
                RowLayout {
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    Button {
                        text: "Cancel"
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        onClicked: navigator.pop()
                    }
                    Button {
                        highlighted: true
                        enabled: newPasswordField.text === confirmPasswordField.text
                        text: "Ok"
                        onClicked: setPassword()
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    }
                }
            }
        }
    }
}
