import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

StyledExpansionPanel {
    label: settingsPanel.hasPin ? qsTr("Change FIDO PIN") : qsTr("Set FIDO PIN")
    ColumnLayout {
        StyledTextField {
            id: currentPinField
            visible: !!yubiKey.currentDevice && settingsPanel.hasPin
            labelText: qsTr("Current PIN")
        }
        StyledTextField {
            id: newPinField
            labelText: qsTr("New PIN")
        }
        StyledTextField {
            id: confirmPinField
            labelText: qsTr("Confirm PIN")
        }
        RowLayout {
            StyledButton {
                id: applyPassword
                text: !!yubiKey.currentDevice && settingsPanel.hasPin ? "Change" : "Set"
                enabled: acceptableInput()
                onClicked: submitPin()
            }
        }
    }

    function acceptableInput() {
        if (!!yubiKey.currentDevice) {
            if (newPinField.text.length > 0 // TODO
                    && (newPinField.text === confirmPinField.text)) {
                return true
            }
        }
        return false
    }

    function submitPin() {
        if (acceptableInput()) {
            if (settingsPanel.hasPin) {
                changePin(currentPinField.text, newPinField.text)
            } else {
                setPin(newPinField.text)
            }
        }
    }

    function clearPinFields() {
        currentPinField.text = ""
        newPinField.text = ""
        confirmPinField.text = ""
    }

    function changePin(currentPin, newPin) {

        yubiKey.fidoChangePin(currentPin, newPin, function (resp) {
            if (resp.success) {
                load()
                clearPinFields()
                navigator.goToSettings()
                navigator.snackBar(qsTr("Changed FIDO2 PIN"))
            } else {
                if (resp.error_id === 'too long') {
                    navigator.snackBarError(qsTr("New PIN is too long"))
                } else if (resp.error_id === 'too short') {
                    navigator.snackBarError(qsTr("New PIN is too short"))
                } else if (resp.error_id === 'wrong pin') {
                    navigator.snackBarError(qsTr("The current PIN is wrong"))
                } else if (resp.error_id === 'currently blocked') {
                    navigator.snackBarError(
                                qsTr("PIN authentication is currently blocked. Remove and re-insert your YubiKey"))
                } else if (resp.error_id === 'blocked') {
                    navigator.snackBarError(qsTr("PIN is blocked"))
                } else if (resp.error_message) {
                    navigator.snackBarError(resp.error_message)
                } else {
                    navigator.snackBarError(resp.error_id)
                }
            }
        })
    }

    function setPin(newPin) {
        yubiKey.fidoSetPin(newPin, function (resp) {
            if (resp.success) {
                load()
                clearPinFields()
                navigator.goToSettings()
                navigator.snackBar(qsTr("FIDO2 PIN was set"))
            } else {
                if (resp.error_id === 'too long') {
                    navigator.snackBarError(qsTr("New PIN is too long"))
                } else if (resp.error_id === 'too short') {
                    navigator.snackBarError(qsTr("New PIN is too short"))
               } else {
                    navigator.snackBarError(
                                navigator.getErrorMessage(
                                    resp.error_id))
                }
            }
        })
    }
}
