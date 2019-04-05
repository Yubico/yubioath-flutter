import QtQuick 2.9
import QtQuick.Controls 2.2
import "utils.js" as Utils

StackView {
    initialItem: noYubiKeyView
    onCurrentItemChanged: {
        if (currentItem) {
            currentItem.forceActiveFocus()
        }
    }

    function clearAndPush(view) {
        clear()
        push(view, StackView.Immediate)
    }

    function goToSettings() {
        if (currentItem.objectName !== 'settingsView') {
            push(settingsView, StackView.Immediate)
        }
    }

    function goToNoYubiKeyView() {
        if (currentItem.objectName !== 'noYubiKeyView') {
            clearAndPush(noYubiKeyView)
        }
    }

    function goToEnterPassword() {
        if (currentItem.objectName !== 'enterPasswordView') {
            clearAndPush(enterPasswordView)
        }
    }
    function goToNewPasswordView() {
        if (currentItem.objectName !== 'newPasswordView') {
            push(newPasswordView, StackView.Immediate)
        }
    }

    function goToCredentials() {
        if (currentItem.objectName !== 'credentialsView') {
            clearAndPush(credentialsView)
        }
    }

    function goToNewCredentialManual() {
        if (currentItem.objectName !== 'newCredentialView') {
            push(newCredentialView.createObject(app, {
                                                    manualEntry: true
                                                }), StackView.Immediate)
        }
    }

    function goToNewCredentialAuto(credential) {
        push(newCredentialView.createObject(app, {
                                                credential: credential,
                                                manualEntry: false
                                            }), StackView.Immediate)
    }

    function confirm(heading, message, cb) {
        var popup = confirmationPopup.createObject(app, {
                                                       heading: heading,
                                                       message: message,
                                                       acceptedCb: cb
                                                   })
        popup.open()
    }

    function snackBar(message) {
        var sb = snackBar.createObject(app, {
                                           message: message
                                       })
        sb.open()
    }

    function snackBarError(message) {
        var sbe = snackBarError.createObject(app, {
                                                 message: message
                                             })
        sbe.open()
    }

    function getErrorMessage(error_id) {
        switch (error_id) {
        case 'no_credential_found':
            return qsTr('No QR code found on screen')
        case 'incorrect_padding':
            return qsTr('Secret key have the wrong format')
        case 'validate_failed':
            return qsTr('Wrong password')
        default:
            return qsTr('Unknown error')
        }
    }

    Component {
        id: credentialsView
        CredentialsView {
        }
    }

    Component {
        id: settingsView
        SettingsView {
        }
    }

    Component {
        id: noYubiKeyView
        NoYubiKeyView {
        }
    }

    Component {
        id: enterPasswordView
        EnterPasswordView {
        }
    }

    Component {
        id: newPasswordView
        NewPasswordView {
        }
    }

    Component {
        id: multipleYubiKeysView
        MultipleYubiKeysView {
        }
    }

    Component {
        id: newCredentialView
        NewCredentialView {
        }
    }

    Component {
        id: confirmationPopup
        ConfirmationPopup {
        }
    }

    Component {
        id: snackBar
        SnackBar {
        }
    }

    Component {
        id: snackBarError
        SnackBar {
            background: Rectangle {
                color: app.yubicoRed
                opacity: 0.8
                radius: 4
            }
        }
    }
}
