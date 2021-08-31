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

    property alias maximumLength: inputPromptField.maximumLength

    property var cancelCb
    property var acceptedCb
    property bool manageMode: false
    property bool pinMode: false
    property bool promptMode: false
    property string returnValue: ""
    property string promptText: ""
    property string promptCurrent: ""
    property string heading
    property string buttonCancel: qsTr("Cancel")
    property string buttonOK: qsTr("OK")
    property string buttonAccept: manageMode ? "Save" : "Continue"
    property string modeText: pinMode ? "PIN" : "password"

    property string text1: manageMode ? qsTr("Enter your current %1 to change it. If you don't know your %1, you'll need to reset the YubiKey, then create a new %1.").arg(modeText)
                                        : qsTr("Enter the %1 for your YubiKey. If you don't know your %1, you'll need to reset the YubiKey.").arg(modeText)
    property string text2: pinMode ? qsTr("Enter your new PIN. A PIN must be at least 4 characters long and can contain letters, numbers and other characters.")
                                        : qsTr("Enter your new password. A password may contain letters, numbers and other characters.")

    property bool hasPin: pinMode && (!!yubiKey.currentDevice && yubiKey.currentDevice.fidoHasPin)
    property bool hasPassword: !pinMode && (!!yubiKey.currentDevice && yubiKey.currentDevice.hasPassword)
    property bool isBio: !!yubiKey.currentDevice && yubiKey.currentDeviceEnabled("FIDO2") && (yubiKey.currentDevice.formFactor === 6 || yubiKey.currentDevice.formFactor === 7)

    Component.onCompleted: {
        if (promptMode) {
            inputPromptField.textField.forceActiveFocus()
        } else if (hasPin || hasPassword) {
            currentPasswordField.textField.forceActiveFocus()
        } else {
            newPasswordField.textField.forceActiveFocus()
        }
    }

    onClosed: {
        destroy()
        navigator.focus = true
    }

    onAccepted: {
        close()
        if(acceptedCb) {
            acceptedCb(returnValue)
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
        if (promptMode && inputPromptField.text.length > 0 && inputPromptField.text !== promptCurrent) {
            return true
        }
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
            if (promptMode) {
                returnValue = inputPromptField.text
                accept()
            }
            if (!manageMode) {
                if (hasPin) {
                    if (isBio) {
                        yubiKey.bioVerifyPin(currentPasswordField.text, function(resp) {
                            if (resp.success) {
                                yubiKey.currentDevice.fidoPinCache = currentPasswordField.text
                                accept()
                            } else {
                                yubiKey.currentDevice.fidoPinCache = ""
                                yubiKey.fingerprints.length = 0
                                if(resp.error_id === "currently blocked" || resp.error_id === "blocked") {
                                    showPinBlockMessage(resp)
                                    reject()
                                }
                                currentPasswordField.error = true
                                currentPasswordField.textField.selectAll()
                                currentPasswordField.textField.forceActiveFocus()
                            }
                        })
                    } else {
                        yubiKey.fidoVerifyPin(currentPasswordField.text, function(resp) {
                            if (resp.success) {
                                yubiKey.currentDevice.fidoPinCache = currentPasswordField.text
                                accept()
                            } else {
                                yubiKey.currentDevice.fidoPinCache = ""
                                yubiKey.credentials.length = 0
                                if(resp.error_id === "currently blocked" || resp.error_id === "blocked") {
                                    showPinBlockMessage(resp)
                                    reject()
                                }
                                currentPasswordField.error = true
                                currentPasswordField.textField.selectAll()
                                currentPasswordField.textField.forceActiveFocus()
                            }
                        })
                    }
                } 
            } else {
                if (pinMode && !promptMode) {
                    if (manageMode) {
                        if (hasPin) {
                            changePIN()

                        } else {
                            setPIN()
                        }
                    }
                } else if (!pinMode && !promptMode) {
                    if (manageMode) {
                        if (hasPassword) {
                            changePassword()
                        } else {
                            setPassword()
                        }
                    }
                }
            }
        }
    }

    function showPinBlockMessage(resp) {
        if(resp.error_id === "currently blocked") {
            cancelCb = navigator.confirm({
                "heading": heading,
                "buttonCancel": "",
                "buttonAccept": buttonOK,
                "buttonPrimary": false,
                "description": qsTr("The YubiKey is locked because wrong PIN was entered too many times. To unlock it, remove and reinsert it.")
            })
        } else if (resp.error_id === "blocked") {
            cancelCb = navigator.confirm({
                "heading": heading,
                "buttonCancel": "",
                "buttonAccept": buttonOK,
                "buttonPrimary": false,
                "description": qsTr("The YubiKey is locked because wrong PIN was entered too many times. You'll need to reset the YubiKey.")
            })
        }
    }

    function setPassword() {
        yubiKey.setPassword(newPasswordField.text, false, function (resp) {
            if (resp.success) {
                navigator.snackBar(qsTr("Password set"))
                yubiKey.currentDevice.hasPassword = true
                accept()
            } else {
                navigator.snackBarError(getErrorMessage(resp.error_id))
                console.log("set password failed:", resp.error_id)
                if (resp.error_id === 'no_device_custom_reader') {
                    yubiKey.clearCurrentDeviceAndEntries()
                }
                reject()
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
                reject()
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
                        accept()
                    } else {
                        navigator.snackBarError(getErrorMessage(resp.error_id))
                        console.log("remove password failed:", resp.error_id)
                        if (resp.error_id === 'no_device_custom_reader') {
                            yubiKey.clearCurrentDeviceAndEntries()
                        }
                        accept()
                    }
                })
            } else {
                navigator.snackBarError(getErrorMessage(resp.error_id))
                console.log("remove password failed:", resp.error_id)
                reject()
            }
        })
    }

    function setPIN() {
        var newPin = newPasswordField.text
        yubiKey.fidoSetPin(newPin, function (resp) {
            if (resp.success) {
                yubiKey.currentDevice.fidoPinCache = newPasswordField.text
                clearPinFields()
                navigator.snackBar(qsTr("FIDO2 PIN was set"))
                accept()
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
                reject()
            }
        })
    }

    function changePIN() {
        var currentPin = currentPasswordField.text
        var newPin = newPasswordField.text
        yubiKey.fidoChangePin(currentPin, newPin, function (resp) {
            if (resp.success) {
                yubiKey.currentDevice.fidoPinCache = newPasswordField.text
                clearPinFields()
                navigator.snackBar(qsTr("Changed FIDO2 PIN"))
                accept()
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
                    yubiKey.pinIsBlocked = true
                } else if (resp.error_message) {
                    navigator.snackBarError(resp.error_message)
                } else {
                    navigator.snackBarError(resp.error_id)
                }
                reject()
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
            visible: hasPin || hasPassword || promptMode
            textFormat: TextEdit.RichText
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
            Layout.bottomMargin: 16
        }

        StyledTextField {
            id: inputPromptField
            visible: promptMode
            labelText: promptText
            text: promptCurrent
            Keys.onEnterPressed: submitForm()
            Keys.onReturnPressed: submitForm()
            onSubmit: submitForm()
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
                Layout.fillHeight: true
                StyledButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Remove")
                    visible: !pinMode
                    enabled: visible && currentPasswordField.text.length > 0
                    KeyNavigation.tab: btnAccept
                    Keys.onReturnPressed: removePassword()
                    onClicked: removePassword()
                }
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
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                KeyNavigation.tab: btnAccept
                Keys.onReturnPressed: reject()
                onClicked: reject()
            }
        }
    }
}
