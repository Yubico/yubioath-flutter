import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.2
import QtQuick.Controls.Material 2.2

Dialog {
    padding: 16
    margins: 0
    spacing: 0
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    Overlay.modal: Rectangle {
        color: "#55000000"
    }

    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: app.width * 0.9 > 600 ? 600 : app.width * 0.9

    background: Rectangle {
        color: defaultElevated
        radius: 4
    }

    property var cancelCb
    property var acceptedCb
    property bool manageMode: false
    property bool pinMode: false
    property string heading
    property string buttonCancel: qsTr("Cancel")
    property string buttonAccept: manageMode ? "Save" : "Continue"
    property string modeText: pinMode ? "PIN" : "password"

    property string text1: manageMode ? qsTr("Enter your current %1 to change it. If you don't know your %1, you'll need to reset the YubiKey, then create a new %1.").arg(modeText)
                                        : qsTr("Enter the %1 for your YubiKey. If you don't know your %1, you'll need to reset the YubiKey.").arg(modeText)
    property string text2: pinMode ? qsTr("Enter your new PIN. A PIN must be at least 4 characters long and can contain letters, numbers and other characters.")
                                        : qsTr("Enter your new password. A password may contain letters, numbers and other characters.")

    property bool hasPin: pinMode && (!!yubiKey.currentDevice && yubiKey.currentDevice.fidoHasPin)
    property bool hasPassword: !pinMode && (!!yubiKey.currentDevice && yubiKey.currentDevice.hasPassword)

    Component.onCompleted: hasPin || hasPassword ? currentPasswordField.textField.forceActiveFocus() : newPasswordField.textField.forceActiveFocus()

    onClosed: {
        navigator.focus = true
    }

    onAccepted: {
        if (pinMode) {
            if (manageMode) {
                if (hasPin) {
                    changePIN()
                } else {
                    setPIN()
                }
            } else {
                console.log("Confirm PIN")
            }
        } else {
            if (manageMode) {
                if (hasPassword) {
                    changePassword()
                } else {
                    setPassword()
                }
            } else {
                console.log("Confirm password")
            }
        }
        close()
        if(acceptedCb) {
            console.log("callback")
            acceptedCb()
        }
        navigator.focus = true
    }

    onRejected: {
        close()
        if (cancelCb) {
            cancelCb()
        }
        navigator.focus = true
    }

    function acceptableInput() {
        if ((hasPin || hasPassword) && currentPasswordField.text.length == 0) {
            return false
        }
        if (!manageMode && currentPasswordField.text.length > 0) {
            return true
        }
        if (newPasswordField.text.length > (pinMode ? 3 : 0)
                && (newPasswordField.text === confirmPasswordField.text)) {
            return true
        }
        return false
    }

    function submitForm() {
        if (acceptableInput()) {
            if (!manageMode) {
                if (hasPin && verifyPIN()) {
                    accept()
                }
                if (hasPin && !verifyPIN()) {
                    currentPasswordField.error = true  
                    currentPasswordField.textField.selectAll()
                    currentPasswordField.textField.forceActiveFocus()
                }
            } else {
                accept()
            }
        }
    }

    function setPassword() {
        yubiKey.setPassword(newPasswordField.text, false, function (resp) {
            if (resp.success) {
                navigator.snackBar(qsTr("Password set"))
                yubiKey.currentDevice.hasPassword = true
            } else {
                navigator.snackBarError(getErrorMessage(resp.error_id))
                console.log("set password failed:", resp.error_id)
                if (resp.error_id === 'no_device_custom_reader') {
                    yubiKey.clearCurrentDeviceAndEntries()
                }
            }
        })
    }

    function changePassword() {
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
        })
    }

    function removePassword() {
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
                })
            } else {
                navigator.snackBarError(getErrorMessage(resp.error_id))
                console.log("remove password failed:", resp.error_id)
            }
        })
    }

    function setPIN() {
        console.log("setPIN()")
        var newPin = newPasswordField.text
        yubiKey.fidoSetPin(newPin, function (resp) {
            if (resp.success) {
                clearPinFields()
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

    function changePIN() {
        console.log("changePIN()")
        var currentPin = currentPasswordField.text
        var newPin = newPasswordField.text
        yubiKey.fidoChangePin(currentPin, newPin, function (resp) {
            if (resp.success) {
                clearPinFields()
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

    function verifyPIN() {
        console.log("verifyPIN()")
        return true
        var pin = currentPasswordField.text
        yubiKey.bioVerifyPin(pin, function (resp) {
            if (resp.success) {
                clearPinFields()
                navigator.snackBar(qsTr("FIDO2 PIN was verified"))
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

    function clearPinFields() {
        currentPasswordField.text = ""
        newPasswordField.text = ""
        confirmPasswordField.text = ""
    }

    ColumnLayout {
        width: parent.width
        spacing: 0

        Label {
            text: heading
            font.pixelSize: 14
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
            Layout.bottomMargin: 16
            visible: heading
        }

        Label {
            text: text1
            color: primaryColor
            opacity: lowEmphasis
            font.pixelSize: 13
            lineHeight: 1.2
            visible: hasPin || hasPassword
            textFormat: TextEdit.RichText
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
            Layout.bottomMargin: 16
        }

        RowLayout {
            spacing: 0
            visible: hasPin || hasPassword
            Layout.bottomMargin: 16
            StyledTextField {
                id: currentPasswordField
                labelText: {
                    if (manageMode) {
                        return pinMode ? qsTr("Current PIN") : qsTr("Current")
                    } else {
                        return pinMode ? qsTr("PIN") : qsTr("Password")
                    }
                }
                echoMode: TextInput.Password
                validateText: "Wrong PIN"
                Keys.onEnterPressed: submitForm()
                Keys.onReturnPressed: submitForm()
                onSubmit: submitForm()
            }
            Item {
                width: 16
            }
            Item {
                Layout.fillWidth: true
            }
        }

        Label {
            text: text2
            color: primaryColor
            opacity: lowEmphasis
            font.pixelSize: 13
            lineHeight: 1.2
            visible: manageMode
            textFormat: TextEdit.RichText
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
            Layout.bottomMargin: 16
        }

        RowLayout {
            spacing: 0
            visible: manageMode
            StyledTextField {
                id: newPasswordField
                labelText: pinMode ? qsTr("PIN") : qsTr("Password")
                echoMode: TextInput.Password
                Keys.onEnterPressed: submitForm()
                Keys.onReturnPressed: submitForm()
                onSubmit: submitForm()
            }
            Item {
                width: 16
            }
            StyledTextField {
                id: confirmPasswordField
                labelText: pinMode ? qsTr("Confirm PIN") : qsTr("Confirm")
                echoMode: TextInput.Password
                Keys.onEnterPressed: submitForm()
                Keys.onReturnPressed: submitForm()
                onSubmit: submitForm()
            }
        }


        DialogButtonBox {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.topMargin: 16
            Layout.bottomMargin: 0
            padding: 0
            background: Rectangle {
                color: "transparent"
            }

            StyledButton {
                id: btnAccept
                text: buttonAccept
                enabled: acceptableInput()
                primary: true
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                KeyNavigation.tab: btnCancel
                Keys.onEnterPressed: submitForm()
                Keys.onReturnPressed: submitForm()
                onClicked: submitForm()
            }

            StyledButton {
                id: btnCancel
                text: qsTr(buttonCancel)
                enabled: true
                flat: true
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                KeyNavigation.tab: btnAccept
                Keys.onReturnPressed: reject()
                onClicked: reject()
            }
        }
    }
}
