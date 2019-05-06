import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ScrollView {

    readonly property int dynamicWidth: 600
    readonly property int dynamicMargin: 32

    objectName: 'settingsView'
    id: pane
    contentWidth: app.width
    contentHeight: app.height
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical: ScrollBar {
        interactive: true
        width: 5
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
    }

    background: Rectangle {
        color: defaultBackground
    }

    function isKeyAvailable() {
        return !!yubiKey.currentDevice
    }

    function deviceInfo() {
        if (isKeyAvailable()) {
            return qsTr("%1 (#%2)").arg(yubiKey.currentDevice.name).arg(
                        yubiKey.currentDevice.serial)
        } else {
            return "Device"
        }
    }

    function setPassword() {
        if (!yubiKey.locked
                && (newPasswordField.text.length > 0
                    && (newPasswordField.text === confirmPasswordField.text))) {
            yubiKey.setPassword(newPasswordField.text, false, function (resp) {
                if (resp.success) {
                    navigator.snackBar("Password set")
                } else {
                    navigator.snackBarError(resp.error_id)
                    console.log(resp.error_id)
                }
            })
        }
    }

    property string title: "Settings"

    ListModel {
        id: themes

        ListElement {
            text: "System Default"
            value: Material.System
        }
        ListElement {
            text: "Light Mode"
            value: Material.Light
        }
        ListElement {
            text: "Dark Mode"
            value: Material.Dark
        }
    }

    spacing: 8
    padding: 0

    //topPadding: 16
    ColumnLayout {
        anchors.fill: parent
        Layout.fillHeight: true
        Layout.fillWidth: true

        Pane {
            id: appPane
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.fillWidth: true
            Layout.bottomMargin: 16
            background: Rectangle {
                color: isDark() ? defaultDarkLighter : defaultLightDarker
                layer.enabled: true
                layer.effect: DropShadow {
                    radius: 4
                    samples: radius * 2
                    verticalOffset: 2
                    horizontalOffset: 2
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
                        text: "Application"
                        color: yubicoGreen
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        topPadding: 8
                        bottomPadding: 8
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledComboBox {
                        id: themeComboBox
                        label: "Appearance"
                        comboBox.textRole: "text"
                        model: themes
                        onCurrentIndexChanged: {
                            settings.theme = themes.get(currentIndex).value
                        }
                        currentIndex: {
                            switch (settings.theme) {
                            case Material.System:
                                return 0
                            case Material.Light:
                                return 1
                            case Material.Dark:
                                return 2
                            default:
                                return 0
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledComboBox {
                        id: authenticatorModeCombobox
                        label: "Authenticator Mode"
                        model: ["CCID (Default)", "OTP"]
                        currentIndex: settings.otpMode ? 1 : 0
                        onCurrentIndexChanged: {
                            if (currentIndex === 1) {
                                settings.otpMode = true
                            } else {
                                settings.otpMode = false
                            }
                        }
                    }
                }

                RowLayout {
                    visible: authenticatorModeCombobox.currentText.indexOf(
                                 "OTP") > -1
                    Label {
                        Layout.fillWidth: true
                        font.pixelSize: 11
                        font.italic: true
                        color: formLabel
                        text: "Note: OTP mode allows usage of the configurable OTP slots on the YubiKey, this should be considered for special usecases only and is not recommended for normal use."
                        wrapMode: Text.WordWrap
                        Layout.rowSpan: 1
                    }
                }

                RowLayout {
                    visible: authenticatorModeCombobox.currentText.indexOf(
                                 "OTP") > -1

                    StyledComboBox {
                        //enabled: slot1CheckBox.checked
                        label: "Slot 1 Digits"
                        model: [6, 7, 8]
                        currentIndex: {

                            if (settings.slot1digits === 6) {
                                return 0
                            }

                            if (settings.slot1digits === 7) {
                                return 1
                            }

                            if (settings.slot1digits === 8) {
                                return 2
                            }
                        }
                        onCurrentTextChanged: settings.slot1digits = currentText
                    }

                    Item {
                        width: 16
                    }

                    StyledComboBox {
                        //enabled: slot2CheckBox.checked
                        label: "Slot 2 Digits"
                        model: [6, 7, 8]
                        currentIndex: {
                            if (settings.slot2digits === 6) {
                                return 0
                            }

                            if (settings.slot2digits === 7) {
                                return 1
                            }

                            if (settings.slot2digits === 8) {
                                return 2
                            }
                        }
                        onCurrentTextChanged: settings.slot2digits = currentText
                    }
                }

                RowLayout {
                    Label {
                        text: Qt.platform.os === "osx" ? "Menu Bar" : "System Tray"
                        font.pixelSize: 10
                        color: formLabel
                    }
                }

                RowLayout {
                    CheckBox {
                        id: sysTrayCheckbox
                        checked: settings.closeToTray
                        text: Qt.platform.os === "osx" ? "Show in menu bar" : "Show in system tray"
                        padding: 0
                        onCheckStateChanged: settings.closeToTray = checked
                        Material.foreground: formText
                    }
                }
                RowLayout {
                    CheckBox {
                        visible: sysTrayCheckbox.checked
                        enabled: sysTrayCheckbox.checked
                        checked: settings.hideOnLaunch
                        padding: 0
                        text: "Hide on launch"
                        onCheckStateChanged: settings.hideOnLaunch = checked
                        Material.foreground: formText
                    }
                }


                /*
                RowLayout {
                    Label {
                        text: "Local Password"
                        font.pixelSize: 10
                        color: formLabel
                    }
                }

                RowLayout {
                    CheckBox {
                        id: rememberPasswordCheckbox
                        checked: false
                        text: "Remember password"
                        padding: 0
                        //onCheckStateChanged: TODO: clear remembered password if deselected
                        Material.foreground: formText
                    }
                }
                */
            }
        }

        //TODO: all device settings should be disabled/hidden if no yubikey is available
        Pane {
            visible: isKeyAvailable()
            id: keyPane
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.topMargin: 8
            Layout.bottomMargin: 8

            background: Rectangle {
                color: isDark() ? defaultDarkLighter : defaultLightDarker
                layer.enabled: true
                layer.effect: DropShadow {
                    radius: 4
                    samples: radius * 2
                    verticalOffset: 2
                    horizontalOffset: 2
                    color: formDropShdaow
                    transparentBorder: true
                }
            }

            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                width: app.width - dynamicMargin
                       < dynamicWidth ? app.width - dynamicMargin : dynamicWidth
                spacing: 16

                RowLayout {
                    Label {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        text: deviceInfo()
                        color: yubicoGreen
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        topPadding: 8
                        bottomPadding: 8
                    }
                }

                StyledExpansionPanel {
                    label: yubiKey.hasPassword ? "Change Password" : "Set Password"
                    description: "For additional security and to prevent unauthorized access the YubiKey may be protected with a password."

                    ColumnLayout {
                        visible: parent.isExpanded
                        Layout.alignment: Qt.AlignRight

                        StyledTextField {
                            id: currentPasswordField
                            visible: yubiKey.hasPassword ? true : false
                            labelText: qsTr("Current Password")
                            echoMode: TextInput.Password
                            Keys.onEnterPressed: setPassword()
                            Keys.onReturnPressed: setPassword()
                        }
                        StyledTextField {
                            id: newPasswordField
                            labelText: qsTr("New Password")
                            echoMode: TextInput.Password
                            Keys.onEnterPressed: setPassword()
                            Keys.onReturnPressed: setPassword()
                        }
                        StyledTextField {
                            id: confirmPasswordField
                            labelText: qsTr("Confirm Password")
                            echoMode: TextInput.Password
                            Keys.onEnterPressed: setPassword()
                            Keys.onReturnPressed: setPassword()
                        }
                        StyledButton {
                            Layout.alignment: Qt.AlignRight
                            text: YubiKey.hasPassword ? "Change Password" : "Set Password"
                            flat: true
                            enabled: !yubiKey.locked
                                     && (newPasswordField.text.length > 0
                                         && (newPasswordField.text
                                             === confirmPasswordField.text)) ? true : false
                            onClicked: setPassword()
                        }
                    }
                }

                StyledExpansionPanel {
                    label: "Manage Passwords"
                    description: "Clear password on this YubiKey or forget the locally remembered password."

                    RowLayout {
                        visible: parent.isExpanded
                        Layout.alignment: Qt.AlignRight

                        StyledButton {
                            Layout.alignment: Qt.AlignRight
                            text: "Forget Password"
                            flat: true
                            enabled: !yubiKey.locked
                                     && (newPasswordField.text.length > 0
                                         && (newPasswordField.text
                                             === confirmPasswordField.text)) ? true : false
                            onClicked: setPassword()
                        }
                        StyledButton {
                            Layout.alignment: Qt.AlignRight
                            text: "Clear Password"
                            flat: true
                            enabled: !yubiKey.locked
                                     && (newPasswordField.text.length > 0
                                         && (newPasswordField.text
                                             === confirmPasswordField.text)) ? true : false
                            onClicked: setPassword()
                        }
                    }
                }

                StyledExpansionPanel {
                    label: "Reset OATH Application"
                    description: "Warning: Resetting the OATH application will delete all credentials and restore factory defaults."

                    RowLayout {
                        visible: parent.isExpanded
                        Layout.alignment: Qt.AlignRight

                        StyledButton {
                            text: "Reset"
                            Layout.alignment: Qt.AlignRight
                            flat: true
                            onClicked: navigator.confirm(
                                           "Are you sure?",
                                           "Are you sure you want to reset the OATH application? This will delete all credentials and restore factory defaults.",
                                           function () {
                                               busy.running = true
                                               yubiKey.reset(function (resp) {
                                                   if (resp.success) {
                                                       entries.clear()
                                                       navigator.snackBar(
                                                                   "Reset completed")
                                                   } else {
                                                       navigator.snackBarError(
                                                                   navigator.getErrorMessage(
                                                                       resp.error_id))
                                                       console.log("reset failed:",
                                                                   resp.error_id)
                                                   }
                                                   busy.running = false
                                               })
                                           })
                        }
                        StyledBusyIndicator {
                            id: busy
                            implicitHeight: 30
                        }
                    }
                }
            }
        }
    }
}
