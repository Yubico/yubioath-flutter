import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2

Pane {
    objectName: 'settingsView'

    property string title: "Settings"

    ListModel {
        id: themes

        ListElement {
            text: "Auto"
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
    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        RowLayout {
            Layout.fillWidth: true
            StyledComboBox {
                id: themeComboBox
                label: "Appearance"
                comboBox.textRole: "text"
                comboBox.model: themes
                comboBox.onCurrentIndexChanged: {
                    settings.theme = themes.get(comboBox.currentIndex).value
                }
                comboBox.currentIndex: {
                    switch (settings.theme) {
                    case Material.Auto:
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
                comboBox.model: ["CCID (Default)", "OTP"]
                comboBox.currentIndex: settings.otpMode ? 1 : 0
                comboBox.onCurrentIndexChanged: {
                    if (comboBox.currentIndex === 1) {
                        settings.otpMode = true
                    } else {
                        settings.otpMode = false
                    }
                }
            }
        }

        RowLayout {
            visible: authenticatorModeCombobox.currentText == "OTP"
            CheckBox {
                id: slot1CheckBox
                text: "Slot 1"
                Layout.fillWidth: true
                checked: settings.slot1inUse
                onCheckedChanged: settings.slot1inUse = checked
            }
            StyledComboBox {
                enabled: slot1CheckBox.checked
                comboBox.model: [6, 7, 8]
                comboBox.currentIndex: {

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
                comboBox.onCurrentTextChanged: settings.slot1digits = comboBox.currentText
            }
        }
        RowLayout {
            visible: authenticatorModeCombobox.currentText == "OTP"
            CheckBox {
                id: slot2CheckBox
                text: "Slot 2"
                Layout.fillWidth: true
                checked: settings.slot2inUse
                onCheckedChanged: settings.slot2inUse = checked
            }
            StyledComboBox {
                enabled: slot2CheckBox.checked
                comboBox.model: [6, 7, 8]
                comboBox.currentIndex: {

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
                comboBox.onCurrentTextChanged: settings.slot2digits = comboBox.currentText
            }
        }

        RowLayout {
            Label {
                text: "Show in system tray"
                Layout.fillWidth: true
            }
            CheckBox {
                id: sysTrayCheckbox
                checked: settings.closeToTray
                onCheckStateChanged: settings.closeToTray = checked
            }
        }
        RowLayout {
            Label {
                enabled: sysTrayCheckbox.checked
                text: "Hide on launch"
                Layout.fillWidth: true
            }
            CheckBox {
                enabled: sysTrayCheckbox.checked
                checked: settings.hideOnLaunch
                onCheckStateChanged: settings.hideOnLaunch = checked
            }
        }
        //TODO: all device settings should be disabled/hidden if no yubikey is available
        Label {
            text: qsTr("Settings for %1 (%2)").arg(
                      yubiKey.currentDevice.name).arg(
                      yubiKey.currentDevice.serial)
        }
        RowLayout {
            Label {
                text: yubiKey.hasPassword ? "YubiKey is protected with password" : "No password is set"
                Layout.fillWidth: true
            }
            StyledButton {
                text: "Set password"
                flat: true
                onClicked: navigator.goToNewPasswordView()
            }
        }
        RowLayout {
            Label {
                text: "Reset OATH Application"
                Layout.fillWidth: true
            }
            StyledButton {
                text: "Reset"
                flat: true
                onClicked: navigator.confirm(
                               "Are you sure?",
                               "Are you sure you want to reset the OATH application? This will delete all credentials and restore factory defaults.",
                               function () {
                                   yubiKey.reset(function (resp) {
                                       if (resp.success) {
                                           entries.clear()
                                           navigator.snackBar("Reset completed")
                                           navigator.goToCredentials()
                                       } else {
                                           navigator.snackBarError(
                                                       resp.error_id)
                                           console.log(resp.error_id)
                                       }
                                   })
                               })
            }
        }
    }
}
