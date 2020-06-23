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

    property bool isShowingAbout

    Accessible.ignored: true
    width: app.width

    function clearAndPush(view) {
        clear()
        push(view, StackView.Immediate)
    }

    function goToSettings() {
        if (currentItem.objectName !== 'settingsView') {
            push(settingsView, StackView.Immediate)
        }
    }

    function goToAbout() {
        if (currentItem.objectName !== 'yubiKeyView') {
            push(yubiKeyView, StackView.Immediate)
        }
    }

    function goToLoading() {
        if (currentItem.objectName !== 'loadingView') {
            push(loadingView, StackView.Immediate)
        }
    }

    function goToEnterPasswordIfNotInSettings() {
        if (currentItem.objectName !== 'enterPasswordView'
                && currentItem.objectName !== 'settingsView'
                && currentItem.objectName !== 'yubiKeyView') {
            clearAndPush(enterPasswordView, StackView.Immediate)
        }
    }

    function home() {
        if (!!yubiKey.currentDevice) {

            if (yubiKey.currentDeviceEnabled("OATH")) {
                // If locked, prompt for password
                if (!!yubiKey.currentDevice && yubiKey.currentDevice.hasPassword
                        && !yubiKey.currentDeviceValidated) {
                    clearAndPush(enterPasswordView)
                    return
                }
                navigator.goToCredentials()
            } else {
                goToYubiKeyView()
            }
        } else {
            clearAndPush(yubiKeyView)
        }

    }

    function goToCredentials(force) {
       if (yubiKey.currentDeviceEnabled("OATH")) {
            yubiKey.calculateAll(function() {

                if (currentItem.objectName !== 'enterPasswordView') {
                    if (!!yubiKey.currentDevice && yubiKey.currentDevice.hasPassword
                            && !yubiKey.currentDeviceValidated) {
                        clearAndPush(enterPasswordView)
                        return
                    }
                }

                if (currentItem.objectName !== 'credentialsView') {
                    clearAndPush(credentialsView)
                }

            })

       } else {
           if (currentItem.objectName !== 'credentialsView') {
               clearAndPush(credentialsView)
           }
       }


    }

    function goToCredentialsIfNotInSettings() {
        if (currentItem.objectName !== 'credentialsView'
                && currentItem.objectName !== 'settingsView') {
            clearAndPush(credentialsView)
        }
    }

    function goToYubiKeyView() {
        if (currentItem.objectName !== 'yubiKeyView'
                && currentItem.objectName !== 'yubiKeyView') {
            clearAndPush(yubiKeyView)
        }
    }


    function goToNewCredential(credential) {
        if (currentItem.objectName !== 'newCredentialView') {
            push(newCredentialView.createObject(app, {
                                                    "credential": credential
                                                }), StackView.Immediate)
        }
    }

    function confirm(options) {
        var popup = confirmationPopup.createObject(app, options)
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
        case 'ccid_error':
            return qsTr('Failed to connect to YubiKey')
        case 'timeout':
            return qsTr('Failed to read from slots')
        case 'failed_to_parse_uri':
            return qsTr('Failed to read credential from QR code')
        case 'wrong_lock_code':
            return qsTr('Wrong lock code')
        case 'interface_config_locked':
            return qsTr('Configuration locked')
        case 'no_pcscd':
            return qsTr('Is the pcscd/smart card service running?')
        case 'no_device_custom_reader':
            return qsTr('No device found')
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
        id: yubiKeyView
        YubiKeyView {
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
        id: loadingView
        LoadingView {
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
