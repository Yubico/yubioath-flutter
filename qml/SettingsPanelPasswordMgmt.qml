import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

StyledExpansionPanel {
    id: passwordManagementPanel
    label: qsTr("Manage password")
    description: !!yubiKey.currentDevice && yubiKey.currentDevice.hasPassword ? "Password is set" : "Password is not set"
    isVisible: yubiKey.currentDeviceEnabled("OATH")
    isTopPanel: true

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
        if (!!yubiKey.currentDevice) {
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
                if (resp.error_id === 'no_device_custom_reader') {
                    yubiKey.clearCurrentDeviceAndEntries()
                }
            }
            clearPasswordFields()
            navigator.goToYubiKey()
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
                if (resp.error_id === 'no_device_custom_reader') {
                    yubiKey.clearCurrentDeviceAndEntries()
                }
            }
            clearPasswordFields()
            navigator.goToYubiKey()
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
                        if (resp.error_id === 'no_device_custom_reader') {
                            yubiKey.clearCurrentDeviceAndEntries()
                        }
                    }
                    clearPasswordFields()
                    navigator.goToYubiKey()
                })
            } else {
                navigator.snackBarError(getErrorMessage(resp.error_id))
                console.log("remove password failed:", resp.error_id)
                navigator.goToYubiKey()
            }
        })
    }

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
