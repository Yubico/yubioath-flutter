import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {

    readonly property int dynamicWidth: 864
    readonly property int dynamicMargin: 32

    id: enterPasswordViewId
    objectName: 'enterPasswordView'
    property string title: qsTr("Unlock YubiKey")

    ScrollBar.vertical: ScrollBar {
        width: 8
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        hoverEnabled: true
        z: 2
    }
    boundsBehavior: Flickable.StopAtBounds

    contentWidth: app.width

    function clear() {
        passwordField.text = ""
        rememberPasswordCheckBox.checked = false
    }

    function validate() {
        if (passwordField.text.valueOf().length > 0) {
            yubiKey.validate(passwordField.text,
                             rememberPasswordCheckBox.checked, function (resp) {
                                 if (resp.success) {
                                     yubiKey.currentDeviceValidated = true
                                     yubiKey.calculateAll(navigator.goToCredentials)
                                 } else {
                                     clear()
                                     navigator.snackBarError(
                                                 navigator.getErrorMessage(
                                                     resp.error_id))
                                     console.log("validate failed:",
                                                 resp.error_id)
                                     passwordField.textField.forceActiveFocus()
                                 }
                             })
        }
    }

    Component.onCompleted: {
        passwordField.textField.forceActiveFocus()
    }

    ColumnLayout {
        anchors.fill: parent
        Layout.fillHeight: true
        Layout.fillWidth: true

        Pane {
            Layout.alignment: Qt.AlignCenter | Qt.AlignTop
            Layout.fillWidth: true
            Layout.maximumWidth: dynamicWidth + dynamicMargin
            Layout.topMargin: 0

            background: Rectangle {
                color: isDark() ? defaultDarkLighter : defaultLightDarker
                layer.enabled: true
                layer.effect: DropShadow {
                    radius: 3
                    samples: radius * 2
                    verticalOffset: 2
                    horizontalOffset: 0
                    color: formDropShdaow
                    transparentBorder: true
                }
            }

            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                width: app.width - dynamicMargin
                       < dynamicWidth ? app.width - dynamicMargin : dynamicWidth
                spacing: 8

                Label {
                    Layout.topMargin: 16
                    text: qsTr("To prevent unauthorized access this YubiKey is protected with a password.")
                    Layout.maximumWidth: app.width - dynamicMargin
                                         < dynamicWidth ? app.width - dynamicMargin : dynamicWidth
                    Layout.rowSpan: 1
                    lineHeight: 1.2
                    wrapMode: Text.WordWrap
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    color: formText
                    Layout.fillWidth: true
                    bottomPadding: 8
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                }

                StyledTextField {
                    id: passwordField
                    labelText: qsTr("Password")
                    echoMode: TextInput.Password
                    Keys.onEnterPressed: validate()
                    Keys.onReturnPressed: validate()
                    Layout.fillWidth: true
                    KeyNavigation.backtab: unlockBtn
                    KeyNavigation.tab: rememberPasswordCheckBox
                    onSubmit: validate()
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                }

                RowLayout {
                    Layout.fillWidth: true
                    CheckBox {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        id: rememberPasswordCheckBox
                        font.pixelSize: 13
                        text: qsTr("Remember password")
                        leftPadding: 0
                        KeyNavigation.backtab: passwordField.textField
                        KeyNavigation.tab: unlockBtn
                        indicator.width: 16
                        indicator.height: 16
                        Layout.leftMargin: 8
                        Layout.topMargin: -8
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    StyledButton {
                        id: unlockBtn
                        text: qsTr("Unlock")
                        toolTipText: qsTr("Unlock YubiKey")
                        enabled: passwordField.text.valueOf().length > 0
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        onClicked: validate()
                        KeyNavigation.backtab: rememberPasswordCheckBox
                        KeyNavigation.tab: passwordField.textField
                        Layout.rightMargin: 8
                        Layout.bottomMargin: 8
                    }
                }
            }
        }
    }
}
