import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {

    id: settingsPanel
    objectName: 'settingsView'
    contentWidth: app.width
    contentHeight: content.implicitHeight

    ScrollBar.vertical: ScrollBar {
        width: 8
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        hoverEnabled: true
        z: 2
    }
    boundsBehavior: Flickable.StopAtBounds

    Keys.onEscapePressed: navigator.home()

    function getDeviceLabel(device) {
        if (!!device) {
            return ("%1").arg(device.name)
        } else {
            return qsTr("Insert your YubiKey")
        }
    }

    function getDeviceDescription(device) {
        if (!!device) {
            return qsTr("Serial number: %1").arg(!!device.serial ? device.serial : "Not available")
        } else if (yubiKey.availableDevices.length > 0
                   && !yubiKey.availableDevices.some(dev => dev.selectable)) {
            return qsTr("No compatible device found")
        } else {
            return qsTr("No device found")
        }
    }

    function clearPasswordFields() {
        currentPasswordField.text = ""
        newPasswordField.text = ""
        confirmPasswordField.text = ""
    }

    function submitPassword() {
        if (acceptableInput()) {
            if (!!yubiKey.currentDevice && yubiKey.currentDevice.hasPassword) {
                changePassword()
            } else {
                setPassword()
            }
        }
    }

    function acceptableInput() {
        if (!!yubiKey.currentDevice && yubiKey.currentDeviceValidated) {
            if (!!yubiKey.currentDevice && yubiKey.currentDevice.hasPassword
                    && currentPasswordField.text.length == 0) {
                return false
            }
            if (newPasswordField.text.length > 0
                    && (newPasswordField.text === confirmPasswordField.text)) {
                return true
            }
        }
        return false
    }

    function changePassword() {
        navigator.goToLoading()
        yubiKey.validate(currentPasswordField.text, false, function (resp) {
            if (resp.success) {
                setPassword()
            } else {
                navigator.snackBarError(getErrorMessage(resp.error_id))
                console.log("change password failed:", resp.error_id)
            }
            clearPasswordFields()
            navigator.goToSettings()
        })
    }

    function setPassword() {
        navigator.goToLoading()
        yubiKey.setPassword(newPasswordField.text, false, function (resp) {
            if (resp.success) {
                navigator.snackBar(qsTr("Password set"))
                yubiKey.currentDevice.hasPassword = true
                passwordManagementPanel.isExpanded = false
            } else {
                navigator.snackBarError(getErrorMessage(resp.error_id))
                console.log("set password failed:", resp.error_id)
            }
            clearPasswordFields()
            navigator.goToSettings()
        })
    }

    function removePassword() {
        navigator.goToLoading()
        yubiKey.validate(currentPasswordField.text, false, function (resp) {
            if (resp.success) {
                yubiKey.removePassword(function (resp) {
                    if (resp.success) {
                        navigator.snackBar(qsTr("Password removed"))
                        yubiKey.currentDevice.hasPassword = false
                        passwordManagementPanel.isExpanded = false
                    } else {
                        navigator.snackBarError(getErrorMessage(resp.error_id))
                        console.log("remove password failed:", resp.error_id)
                    }
                    clearPasswordFields()
                    navigator.goToSettings()
                })
            } else {
                navigator.snackBarError(getErrorMessage(resp.error_id))
                console.log("remove password failed:", resp.error_id)
            }

        })
    }

    property string title: qsTr("")

    ListModel {
        id: themes

        ListElement {
            text: qsTr("System default")
            value: Material.System
        }
        ListElement {
            text: qsTr("Light mode")
            value: Material.Light
        }
        ListElement {
            text: qsTr("Dark mode")
            value: Material.Dark
        }
    }


    ColumnLayout {
        id: content
        anchors.fill: parent
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        spacing: 0

        StyledExpansionContainer {
            id: keyPane
            sectionTitle: qsTr("Device")

            StyledExpansionPanel {
                id: currentDevicePanel
                label: getDeviceLabel(yubiKey.currentDevice)
                description: getDeviceDescription(yubiKey.currentDevice)
                keyImage: !!yubiKey.currentDevice ? yubiKey.getCurrentDeviceImage() : "../images/yubikeys-large-transparent"
                isTopPanel: true
                Layout.fillWidth: true
                isEnabled: yubiKey.availableDevices.length > 1

                ButtonGroup {
                    id: deviceButtonGroup
                }

                ColumnLayout {
                    Layout.fillWidth: true

                    Repeater {
                        model: yubiKey.availableDevices
                        onModelChanged: {
                            if (yubiKey.availableDevices.length < 2) {
                                currentDevicePanel.isExpanded = false
                            }
                        }
                        StyledRadioButton {
                            Layout.fillWidth: true
                            objectName: index
                            checked: !!yubiKey.currentDevice
                                     && modelData.serial === yubiKey.currentDevice.serial
                            text: getDeviceLabel(modelData)
                            description: getDeviceDescription(modelData)
                            enabled: modelData.selectable
                            buttonGroup: deviceButtonGroup
                        }
                    }

                    StyledButton {
                        id: selectBtn
                        Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                        text: "Select"
                        enabled: {
                            if (!!yubiKey.availableDevices && !!deviceButtonGroup.checkedButton) {
                                var dev = yubiKey.availableDevices[deviceButtonGroup.checkedButton.objectName]
                                return dev !== yubiKey.currentDevice
                            } else {
                                return false
                            }
                        }
                        onClicked: {
                            yubiKey.refreshDevicesDefault()
                            var dev = yubiKey.availableDevices[deviceButtonGroup.checkedButton.objectName]
                            yubiKey.selectCurrentSerial(dev.serial,
                                                        function (resp) {
                                                            if (resp.success) {
                                                                entries.clear()
                                                                yubiKey.currentDevice = dev
                                                                currentDevicePanel.expandAction()
                                                                yubiKey.calculateAll()
                                                            } else {
                                                                console.log("select device failed", resp.error_id)
                                                            }
                                                        })
                        }
                    }
                }
            }

            StyledExpansionPanel {
                id: passwordManagementPanel
                label: !!yubiKey.currentDevice && yubiKey.currentDevice.hasPassword ? qsTr("Change password") : qsTr("Set password")
                description: qsTr("For additional security the YubiKey may be protected with a password.")
                isVisible: !!yubiKey.currentDevice

                ColumnLayout {

                    StyledTextField {
                        id: currentPasswordField
                        visible: !!yubiKey.currentDevice && yubiKey.currentDevice.hasPassword
                        labelText: qsTr("Current password")
                        echoMode: TextInput.Password
                        Keys.onEnterPressed: submitPassword()
                        Keys.onReturnPressed: submitPassword()
                        onSubmit: submitPassword()
                    }
                    StyledTextField {
                        id: newPasswordField
                        labelText: qsTr("New password")
                        echoMode: TextInput.Password
                        Keys.onEnterPressed: submitPassword()
                        Keys.onReturnPressed: submitPassword()
                        onSubmit: submitPassword()
                    }
                    StyledTextField {
                        id: confirmPasswordField
                        labelText: qsTr("Confirm password")
                        echoMode: TextInput.Password
                        Keys.onEnterPressed: submitPassword()
                        Keys.onReturnPressed: submitPassword()
                        onSubmit: submitPassword()
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignRight | Qt.AlignTop
                        StyledButton {
                            id: removePasswordBtn
                            visible: !!yubiKey.currentDevice && yubiKey.currentDevice.hasPassword
                            enabled: currentPasswordField.text.length > 0
                            text: "Remove"
                            onClicked: navigator.confirm({
                                                       "heading": qsTr("Remove password?"),
                                                       "description": qsTr("A password will not be required to access the accounts anymore."),
                                                       "warning": false,
                                                       "buttonAccept": qsTr("Remove password"),
                                                       "acceptedCb": function () {
                                                           removePassword()
                                                       }
                                                         })
                        }
                        StyledButton {
                            id: applyPassword
                            text: !!yubiKey.currentDevice && yubiKey.currentDevice.hasPassword ? "Change" : "Set"
                            enabled: acceptableInput()
                            onClicked: submitPassword()
                        }
                    }
                }
            }

            StyledExpansionPanel {
                label: qsTr("Reset")
                description: qsTr("Warning: Reset will delete all accounts and restore factory defaults.")
                isEnabled: false
                isVisible: !!yubiKey.currentDevice

                toolButtonIcon: "../images/reset.svg"
                toolButtonToolTip: qsTr("Reset device")
                toolButton.onClicked: navigator.confirm({
                                                  "heading": qsTr("Reset device?"),
                                                  "message": qsTr("This will delete all accounts and restore factory defaults of your YubiKey."),
                                                  "description": qsTr("There is NO going back from here, if you do not know what you are doing, do NOT do this."),
                                                  "buttonAccept": qsTr("Reset device"),
                                                  "acceptedCb": function () {
                                                      navigator.goToLoading()
                                                      yubiKey.reset(function (resp) {
                                                          if (resp.success) {
                                                              entries.clear()
                                                              navigator.snackBar(
                                                                          qsTr("Reset completed"))
                                                              yubiKey.currentDeviceValidated = true
                                                              yubiKey.currentDevice.hasPassword = false

                                                          } else {
                                                              navigator.snackBarError(
                                                                          navigator.getErrorMessage(
                                                                              resp.error_id))
                                                              console.log("reset failed:",
                                                                          resp.error_id)
                                                          }
                                                          navigator.goToSettings()
                                                      })
                                                  }
               })
            }

        }

        StyledExpansionContainer {
            id: appPane
            sectionTitle: qsTr("Application")

            StyledExpansionPanel {
                label: qsTr("Appearance")
                description: qsTr("Change the visual appearance of the application.")
                metadata: "dark light mode theme"
                isTopPanel: true

                ColumnLayout {

                    RowLayout {
                        Layout.fillWidth: true
                        StyledComboBox {
                            id: themeComboBox
                            label: qsTr("Theme")
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
                }
            }

            StyledExpansionPanel {
                id: interfacePanel
                label: qsTr("Custom reader")
                description: qsTr("Specify a custom reader for YubiKey.")
                metadata: "ccid otp slot custom readers nfc"

                property bool aboutToChange: customReaderCheckbox.checked !== settings.useCustomReader
                                             || readerFilter.text !== settings.customReaderName && readerFilter.text.length > 0

                function isValidMode() {
                    return aboutToChange
                }

                function setInterface() {
                    settings.useCustomReader = customReaderCheckbox.checked
                    settings.customReaderName = readerFilter.text
                    yubiKey.clearCurrentDeviceAndEntries()
                    yubiKey.refreshDevicesDefault()
                    navigator.goToSettings()
                    navigator.snackBar(qsTr("Interface changed"))
                    interfacePanel.isExpanded = false
                }

                ColumnLayout {
                    CheckBox {
                        id: customReaderCheckbox
                        checked: settings.useCustomReader
                        text: qsTr("Enable custom reader")
                        padding: 0
                        indicator.width: 16
                        indicator.height: 16
                    }
                    Label {
                        Layout.alignment: Qt.AlignRight | Qt.AlignTop
                        Layout.fillWidth: true
                        font.pixelSize: 13
                        color: primaryColor
                        opacity: lowEmphasis
                        text: "Specify a custom reader, useful for example when using a NFC reader."
                        textFormat: TextEdit.RichText
                        wrapMode: Text.WordWrap
                        elide: Text.ElideRight
                        lineHeight: 1.1
                    }
                }

                ColumnLayout {
                    Layout.topMargin: 8
                    visible: customReaderCheckbox.checked

                    RowLayout {
                        visible: yubiKey.availableReaders.length > 0
                        StyledComboBox {
                            id: connectedReaders
                            enabled: yubiKey.availableReaders.length > 0
                            visible: yubiKey.availableReaders.length > 0
                            label: qsTr("Connected readers")
                            model: yubiKey.availableReaders
                        }
                        StyledButton {
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            text: qsTr("Use as filter")
                            flat: true
                            enabled: yubiKey.availableReaders.length > 0
                            visible: yubiKey.availableReaders.length > 0
                            onClicked: readerFilter.text = connectedReaders.currentText
                        }
                    }

                    StyledTextField {
                        id: readerFilter
                        labelText: qsTr("Custom reader filter")
                        text: settings.customReaderName
                    }
                }

                StyledButton {
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                    text: "Apply"
                    enabled: interfacePanel.isValidMode()
                    onClicked: interfacePanel.setInterface()
                }
            }

            StyledExpansionPanel {
                label: Qt.platform.os === "osx" ? "Menu bar" : "System tray"
                description: qsTr("Configure where and how the application is visible.")

                ColumnLayout {
                    CheckBox {
                        id: sysTrayCheckbox
                        checked: settings.closeToTray
                        text: Qt.platform.os === "osx" ? qsTr("Show in menu bar") : qsTr("Show in system tray")
                        padding: 0
                        indicator.width: 16
                        indicator.height: 16
                        onCheckStateChanged: {
                            if(!checked) {
                                hideOnLaunchCheckbox.checked = false
                            }
                            settings.closeToTray = checked
                        }
                    }

                    CheckBox {
                        id: hideOnLaunchCheckbox
                        enabled: sysTrayCheckbox.checked
                        checked: settings.hideOnLaunch
                        text: qsTr("Hide on launch")
                        padding: 0
                        indicator.width: 16
                        indicator.height: 16
                        onCheckStateChanged: settings.hideOnLaunch = checked
                    }
                }
            }

            StyledExpansionPanel {
                label: qsTr("Clear passwords")
                description: qsTr("Delete all saved passwords.")
                isEnabled: false
                isBottomPanel: true
                toolButtonIcon: "../images/delete.svg"
                toolButtonToolTip: qsTr("Clear")
                toolButton.onClicked: navigator.confirm({
                                                  "heading": qsTr("Clear passwords?"),
                                                  "message": qsTr("This will delete all saved passwords."),
                                                  "description": qsTr("A password prompt will appear the next time a YubiKey with a password is used."),
                                                  "buttonAccept": qsTr("Clear passwords"),
                                                  "acceptedCb": function() {
                                                    yubiKey.clearLocalPasswords(function (resp) {
                                                      if (resp.success) {
                                                        navigator.snackBar(qsTr("Passwords cleared"))
                                                      }
                  })}
               })
            }
        }
    }
}
