import QtQuick 2.9
import QtQuick.Controls 2.2

StackView {

    // Navigator is responsible for changing the views, and showing error messages.
    // It can also report back the current view, and show confirmaton dialogs.

    initialItem: authenticatorView

    onCurrentItemChanged: {
        if (currentItem) {
            currentItem.forceActiveFocus()
        }
    }

    Accessible.ignored: true
    width: app.width

    function clearAndPush(view) {
        clear()
        push(view, StackView.Immediate)
    }

    function isInFlickable() {
        return !!currentItem && currentItem.objectName.includes('Flickable')
    }


    function isInAuthenticator() {
        return !!currentItem && currentItem.objectName === 'authenticatorView'
    }

    function hasSelectedOathCredential() {
        return !!currentItem && !!currentItem.currentCredentialCard
    }

    function oathCopySelectedCredential() {
        currentItem.currentCredentialCard.calculateCard(true)
    }

    function oathDeleteSelectedCredential() {
        currentItem.currentCredentialCard.deleteCard()
    }

    function oathToggleFavoriteSelectedCredential() {
        currentItem.currentCredentialCard.toggleFavorite()
    }

    function isInYubiKeyView() {
        return !!currentItem && currentItem.objectName === 'yubiKeyView'
    }

    function isInSettings() {
        return !!currentItem && currentItem.objectName === 'settingsView'
    }

    function isInLoading() {
        return !!currentItem && currentItem.objectName === 'loadingView'
    }

    function isInNewOathCredential() {
        return !!currentItem && currentItem.objectName === 'newCredentialView'
    }

    function isInEnterPassword() {
        return !!currentItem && currentItem.objectName === 'enterPasswordView'
    }

    function isInAbout() {
        return !!currentItem && currentItem.objectName === 'aboutView'
    }

    function goToAuthenticator() {

        // Before navigating to Authenticator view,
        // Make sure credentials are up to date by doing
        // a calculate all call.

        function pushAuthenticatorView() {
            if (currentItem.objectName !== 'authenticatorView') {
                clearAndPush(authenticatorView)
            }
        }

        if (yubiKey.currentDeviceEnabled("OATH")) {
            yubiKey.oathCalculateAllOuter(pushAuthenticatorView)
        } else {
            pushAuthenticatorView()
        }
    }

    function goToSettings() {
        if (currentItem.objectName !== 'settingsView') {
            clearAndPush(settingsView, StackView.Immediate)
        }
    }

    function goToAbout() {
        if (currentItem.objectName !== 'aboutView') {
            clearAndPush(aboutView, StackView.Immediate)
        }
    }

    function goToYubiKey() {
        if (currentItem.objectName !== 'yubiKeyView') {
            clearAndPush(yubiKeyView, StackView.Immediate)
        }
    }

    function goToLoading() {
        if (currentItem.objectName !== 'loadingView') {
            push(loadingView, StackView.Immediate)
        }
    }

    function goToEnterPassword() {
        if (currentItem.objectName !== 'enterPasswordView') {
            clearAndPush(enterPasswordView, StackView.Immediate)
        }
    }

    function goToNewCredential(credential) {
        if (currentItem.objectName !== 'newCredentialView') {
            clearAndPush(newCredentialView, StackView.Immediate)
        }
    }

    function goToCustomReader() {
        if (currentItem.objectName !== 'customReaderView') {
            push(customReaderView, StackView.PushTransition)
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
        var sb = snackBarComponent.createObject(app, {
                                                    "message": message,
                                                    "backgroundColor": yubicoRed
                                                })
        sb.open()
    }

    function snackBarInfo(message) {
        var sb = snackBarComponent.createObject(app, {
                                                    "message": message,
                                                    "backgroundColor": snackBarInfoBg,
                                                })
        sb.open()
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
        id: authenticatorView
        AuthenticatorView {
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
        id: aboutView
        AboutView {
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
        id: customReaderView
        FlickableCustomReader {
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
}
