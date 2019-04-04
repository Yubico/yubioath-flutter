import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2

Pane {
    objectName: 'settingsView'

    property string title: "Settings"

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        RowLayout {
            Layout.fillWidth: true
            Label {
                text: "Theme"
                Layout.fillWidth: true
            }
            StyledComboBox {
                id: themeComboBox
                model: ["Auto", "Light", "Dark"]
                onCurrentTextChanged: app.setTheme(currentText)
            }
        }

        RowLayout {
            Label {
                text: "Authenticator mode"
                Layout.fillWidth: true
            }
            StyledComboBox {
                id: authenticatorModeCombobox
                model: ["CCID (Default)", "OTP"]
            }
        }

        RowLayout {
            visible: authenticatorModeCombobox.currentText == "OTP"
            CheckBox {
                id: slot1CheckBox
                text: "Slot 1"
                Layout.fillWidth: true
            }
            StyledComboBox {
                enabled: slot1CheckBox.checked
                model: ["6", "7", "8"]
            }
        }
        RowLayout {
            visible: authenticatorModeCombobox.currentText == "OTP"
            CheckBox {
                id: slot2CheckBox
                text: "Slot 2"
                Layout.fillWidth: true
            }
            StyledComboBox {
                enabled: slot2CheckBox.checked
                model: ["6", "7", "8"]
            }
        }

        RowLayout {
            visible: authenticatorModeCombobox.currentText == "CCID (Default)"

            Label {
                text: "Use custom reader"
                Layout.fillWidth: true
            }

            CheckBox {
                id: customReaderCheckbox
            }
        }

        StyledComboBox {
            visible: authenticatorModeCombobox.currentText == "CCID (Default)"
            Layout.fillWidth: true
            enabled: customReaderCheckbox.checked
            model: ["Yubico Yubikey 4 U2F+CCID 00 00", "Alcor Micro AU9560 01 00", "HID Global OMNIKEY 5022 Smart Card Reader 02 00"]
        }

        RowLayout {
            Label {
                text: "2 remebered passwords"
                Layout.fillWidth: true
            }
            StyledButton {
                text: "Clear"
                flat: true
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
                      yubiKey.availableDevices[0].name).arg(
                      yubiKey.availableDevices[0].serial)
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
