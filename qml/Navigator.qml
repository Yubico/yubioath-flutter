import QtQuick 2.9
import QtQuick.Controls 2.2
import "utils.js" as Utils

StackView {
    initialItem: credentialsView
    onCurrentItemChanged: {
        if (currentItem) {
            currentItem.forceActiveFocus()
        }
    }

    function clearAndPush(view) {
        if (currentItem.objectName !== 'settingsView') {
            clear()
            push(view, StackView.Immediate)
        }
    }

    function goToSettings() {
        if (currentItem.objectName !== 'settingsView') {
            push(settingsView, StackView.Immediate)
        }
    }

    function goToEnterPassword() {
        if (currentItem.objectName !== 'enterPasswordView') {
            clearAndPush(enterPasswordView, StackView.Immediate)
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
                                                    "manualEntry": true
                                                }), StackView.Immediate)
        }
    }

    function goToNewCredentialAuto(credential) {
        push(newCredentialView.createObject(app, {
                                                "credential": credential,
                                                "manualEntry": false
                                            }), StackView.Immediate)
    }

    function confirm(heading, message, cb) {
        var popup = confirmationPopup.createObject(app, {
                                                       "heading": heading,
                                                       "message": message,
                                                       "acceptedCb": cb
                                                   })
        popup.open()
    }

    function snackBar(message) {
        var sb = snackBarComponent.createObject(app, {
                                                    "message": message
                                                })
        sb.open()
    }

    function snackBarError(message) {
        var sbe = snackBarErrorComponent.createObject(app, {
                                                          "message": message
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
        case 'no_space':
            return qsTr('No space available')
        case 'no_current_device':
            return qsTr('No YubiKey found')
        case 'open_device_failed':
            return qsTr('Failed to connect to YubiKey')
        case 'timeout':
            return qsTr('Failed to read from slots')
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
        id: newCredentialView
        NewCredentialView {
        }
    }

    Component {
        id: enterPasswordView
        EnterPasswordView {
        }
    }

    Component {
        id: confirmationPopup
        ConfirmationPopup {
        }
    }

    Component {
        id: snackBarComponent
        SnackBar {
        }
    }

    Component {
        id: snackBarErrorComponent
        SnackBar {
            buttonColor: yubicoRed
        }
    }
}
