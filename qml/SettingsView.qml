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
            return qsTr("Serial number: %1").arg(!!device.serial ? device.serial : "Not Available")
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

    ListModel {
        id: otpModeDigits

        ListElement {
            text: "Off"
            value: 0
        }
        ListElement {
            text: "6"
            value: 6
        }
        ListElement {
            text: "7"
            value: 7
        }
        ListElement {
            text: "8"
            value: 8
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
                                                  "acceptedCb": function() {
                                                    yubiKey.clearLocalPasswords(function (resp) {
                                                      if (resp.success) {
                                                        navigator.snackBar(qsTr("Passwords cleared"))
                                                      }
                  })}
               })
            }

            StyledExpansionPanel {
                id: interfacePanel
                label: qsTr("Custom reader")
                description: qsTr("Configure how to communicate with the YubiKey.")
                metadata: "ccid otp slot custom readers nfc"

                property bool otpModeSelected: interfaceCombobox.currentIndex === 2
                property bool customReaderSelected: interfaceCombobox.currentIndex === 1
                property bool aboutToChange: (otpModeSelected !== settings.otpMode)
                                             || (slot1DigitsComboBox.currentIndex
                                                 !== getComboBoxIndex(
                                                     settings.slot1digits))
                                             || (slot2DigitsComboBox.currentIndex
                                                 !== getComboBoxIndex(
                                                     settings.slot2digits))
                                             || customReaderSelected !== settings.useCustomReader
                                             || readerFilter.text !== settings.customReaderName && readerFilter.text.length > 0

                function isValidMode() {
                    return aboutToChange
                            && ((otpModeSelected
                                 && (slot1DigitsComboBox.currentIndex !== 0
                                     || slot2DigitsComboBox.currentIndex !== 0))
                                || !otpModeSelected)
                }

                function setInterface() {
                    settings.slot1digits = otpModeDigits.get(
                                slot1DigitsComboBox.currentIndex).value
                    settings.slot2digits = otpModeDigits.get(
                                slot2DigitsComboBox.currentIndex).value
                    settings.otpMode = otpModeSelected
                    settings.useCustomReader = customReaderSelected
                    settings.customReaderName = readerFilter.text
                    yubiKey.clearCurrentDeviceAndEntries()
                    yubiKey.refreshDevicesDefault()
                    navigator.goToSettings()
                    navigator.snackBar(qsTr("Interface changed"))
                    interfacePanel.isExpanded = false
                }

                function getComboBoxIndex(digits) {
                    switch (digits) {
                    case 0:
                        return 0
                    case 6:
                        return 1
                    case 7:
                        return 2
                    case 8:
                        return 3
                    default:
                        return 0
                    }
                }

                ColumnLayout {


                    RowLayout {
                        Layout.fillWidth: true
                        StyledComboBox {
                            id: interfaceCombobox
                            label: qsTr("Interface")
                            model: ["CCID (recommended)", "CCID with custom reader", "OTP"]
                            currentIndex: getCurrentIndex()

                            function getCurrentIndex() {
                                if (settings.otpMode) {
                                    return 2
                                }
                                if (settings.useCustomReader && !settings.otpMode) {
                                    return 1
                                }
                                // default
                                return 0
                            }
                        }
                    }
                }

                RowLayout {
                    visible: interfacePanel.otpModeSelected
                    Label {
                        Layout.fillWidth: true
                        font.pixelSize: 12
                        color: primaryColor
                        opacity: lowEmphasis
                        text: qsTr("Using OTP slots should be considered for special cases only.")
                        wrapMode: Text.WordWrap
                        Layout.rowSpan: 1
                        bottomPadding: 8
                    }
                }

                RowLayout {
                    visible: interfacePanel.otpModeSelected

                    StyledComboBox {
                        id: slot1DigitsComboBox
                        label: qsTr("Slot 1 digits")
                        comboBox.textRole: "text"
                        model: otpModeDigits
                        currentIndex: interfacePanel.getComboBoxIndex(
                                          settings.slot1digits)
                    }

                    Item {
                        width: 16
                    }

                    StyledComboBox {
                        id: slot2DigitsComboBox
                        label: qsTr("Slot 2 digits")
                        comboBox.textRole: "text"
                        model: otpModeDigits
                        currentIndex: interfacePanel.getComboBoxIndex(
                                          settings.slot2digits)
                    }
                }

                ColumnLayout {
                    visible: interfacePanel.customReaderSelected

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
                            Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                            text: qsTr("Use as filter")
                            flat: true
                            enabled: yubiKey.availableReaders.length > 0
                            visible: yubiKey.availableReaders.length > 0
                            onClicked: readerFilter.text = connectedReaders.currentText
                        }
                    }

                    StyledTextField {
                        id: readerFilter
                        enabled: interfacePanel.customReaderSelected
                        visible: interfacePanel.customReaderSelected
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
                label: Qt.platform.os === "osx" ? "Menu Bar" : "System Tray"
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
        }

        StyledExpansionContainer {
            sectionTitle: qsTr("Interfaces")
            visible: !!yubiKey.currentDevice

            StyledExpansionPanel {
                label: qsTr("Interfaces")
                description: qsTr("Enable/disable active interfaces on the YubiKey")
                isTopPanel: true
                isVisible: true

                ColumnLayout {
                    Text {
                        text: "There's nothing to see here"
                    }
                }
            }
        }

        StyledExpansionContainer {
            id: oathSettings
            sectionTitle: qsTr("Security Codes (OATH)")
            visible: !!yubiKey.currentDevice

            StyledExpansionPanel {
                id: passwordManagementPanel
                label: !!yubiKey.currentDevice && yubiKey.currentDevice.hasPassword ? qsTr("Change password") : qsTr("Set password")
                description: qsTr("For additional security the YubiKey may be protected with a password.")
                isTopPanel: true
                isVisible: true

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
                            flat: true
                            onClicked: navigator.confirm({
                                                       "heading": qsTr("Remove password?"),
                                                       "description": qsTr("A password will not be required to access the accounts anymore."),
                                                       "warning": false,
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
                isVisible: true
                toolButtonIcon: "../images/reset.svg"
                toolButtonToolTip: qsTr("Reset device")
                toolButton.onClicked: navigator.confirm({
                                                  "heading": qsTr("Reset device?"),
                                                  "message": qsTr("This will delete all accounts and restore factory defaults of your YubiKey."),
                                                  "description": qsTr("There is NO going back from here, if you do not know what you are doing, do NOT do this."),
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
            sectionTitle: qsTr("Slot configuration")
            visible: !!yubiKey.currentDevice

            StyledExpansionPanel {
                label: qsTr("Short touch (slot 1)")
                description: qsTr("This slot is condfigured")
                isTopPanel: true
                isVisible: true

                ColumnLayout {
                    Text {
                        text: "There's nothing to see here"
                    }
                }
            }

            StyledExpansionPanel {
                label: qsTr("Long touch (slot 2)")
                description: qsTr("This slot is empty")
                isVisible: true

                ColumnLayout {
                    Text {
                        text: "There's nothing to see here"
                    }
                }
            }

            StyledExpansionPanel {
                label: qsTr("Swap configuration")
                description: qsTr("Reverse the slot configuration")
                isVisible: true

                ColumnLayout {
                    Text {
                        text: "There's nothing to see here"
                    }
                }
            }
        }

        StyledExpansionContainer {
            sectionTitle: qsTr("PIV certificates")
            visible: !!yubiKey.currentDevice

            StyledExpansionPanel {
                label: qsTr("PIN management")
                description: qsTr("PIN, PUK, Management Key")
                isTopPanel: true
                isVisible: true

                ColumnLayout {
                    Text {
                        text: "There's nothing to see here"
                    }
                }
            }

            StyledExpansionPanel {
                label: qsTr("Certificates")
                description: qsTr("No certificates loaded")
                isVisible: true

                ColumnLayout {
                    Text {
                        text: "There's nothing to see here"
                    }
                }
            }

            StyledExpansionPanel {
                label: qsTr("Setup for macOS")
                description: qsTr("Login to macOS with your YubiKey")
                isVisible: true

                ColumnLayout {
                    Text {
                        text: "There's nothing to see here"
                    }
                }
            }

            StyledExpansionPanel {
                label: qsTr("Reset")
                description: qsTr("Warning: reset will delete all certificates and restore factory defaults")
                isTopPanel: true
                isVisible: true

                ColumnLayout {
                    Text {
                        text: "There's nothing to see here"
                    }
                }
            }

        }

        StyledExpansionContainer {
            sectionTitle: qsTr("Security Keys (FIDO2)")
            visible: !!yubiKey.currentDevice

            StyledExpansionPanel {
                label: qsTr("Create a PIN")
                description: qsTr("Protect your security key with a PIN")
                metadata: "fido2"
                isTopPanel: true
                isVisible: true

                ColumnLayout {
                    Text {
                        text: "There's nothing to see here"
                    }
                }
            }

            StyledExpansionPanel {
                label: qsTr("Manage sign-in data")
                description: qsTr("View and delete the sifgn-in data stored on your secuirty key")
                metadata: "fido2"
                isVisible: true

                ColumnLayout {
                    Text {
                        text: "There's nothing to see here"
                    }
                }
            }

            StyledExpansionPanel {
                label: qsTr("Reset your security key")
                description: qsTr("This will erase all data on the security key, including its PIN")
                metadata: "fido2"
                isVisible: true

                ColumnLayout {
                    Text {
                        text: "There's nothing to see here"
                    }
                }
            }
        }

        Item {
            height: 32
        }
    }
}
