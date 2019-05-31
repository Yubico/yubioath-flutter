import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ScrollView {

    readonly property int dynamicWidth: 864
    readonly property int dynamicMargin: 32

    id: enterPasswordViewId
    objectName: 'enterPasswordView'
    property string title: "Unlock YubiKey"

    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical: ScrollBar {
        interactive: true
        width: 5
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
    }

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
                                     yubiKey.calculateAll(
                                                 navigator.goToCredentials)
                                 } else {
                                     clear()
                                     navigator.snackBarError(
                                                 navigator.getErrorMessage(
                                                     resp.error_id))
                                     console.log("validate failed:",
                                                 resp.error_id)
                                 }
                             })
        }
    }

    spacing: 8
    padding: 0

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
            Layout.topMargin: 32
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

                RowLayout {
                    Label {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        text: "Unlock YubiKey"
                        color: Material.primary
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        topPadding: 8
                        bottomPadding: 8
                        Layout.fillWidth: true
                    }
                }

                Label {
                    text: "To prevent unauthorized access this YubiKey is protected with a password."
                    Layout.maximumWidth: app.width - dynamicMargin
                                         < dynamicWidth ? app.width - dynamicMargin : dynamicWidth
                    Layout.rowSpan: 1
                    lineHeight: 1.2
                    wrapMode: Text.WordWrap
                    font.pixelSize: 13
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.fillWidth: true
                    topPadding: 8
                    color: formText
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
                }

                RowLayout {
                    CheckBox {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        id: rememberPasswordCheckBox
                        font.pixelSize: 12
                        text: "Remember password"
                        leftPadding: 0
                        indicator.width: 16
                        indicator.height: 16
                        KeyNavigation.backtab: passwordField.textField
                        KeyNavigation.tab: unlockBtn
                    }
                }

                StyledButton {
                    id: unlockBtn
                    text: "Unlock"
                    toolTipText: "Unlock YubiKey"
                    enabled: passwordField.text.valueOf().length > 0
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    onClicked: validate()
                    KeyNavigation.backtab: rememberPasswordCheckBox
                    KeyNavigation.tab: passwordField.textField
                }
            }
        }
    }
}
