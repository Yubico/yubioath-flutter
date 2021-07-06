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

    function isInAuthenticator() {
        return !!currentItem && currentItem.objectName === 'authenticatorView'
    }

    function isInYubiKeySection() {
        return !!currentItem && currentItem.objectName.includes('yubiKey')
    }

    function isInYubiKeyView() {
        return !!currentItem && currentItem.objectName === 'yubiKeyView'
    }

    function isInSettings() {
        return !!currentItem && currentItem.objectName === 'settingsView'
    }

    function isInFlickable() {
        if (!!currentItem && currentItem.objectName.includes('yubiKeyWebAuthnView'))
            return true
        return !!currentItem && currentItem.objectName.includes('Flickable')
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

    function isInNewFingerprint() {
        return !!currentItem && currentItem.objectName === 'newFingerPrintViewFlickable'
    }

    function goToAuthenticator() {
        settings.activeView = 'authenticatorView'

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
        settings.activeView = 'yubiKeyView'
        if (currentItem.objectName !== 'yubiKeyView') {
            clearAndPush(yubiKeyView, StackView.Immediate)
        }
    }

    function goToWebAuthnView() {
        if (currentItem.objectName !== 'webAuthnView') {
            push(yubiKeyWebAuthnView, StackView.PushTransition)
        }
    }

    function goToFingerPrintsView() {
        if (currentItem.objectName !== 'fingerPrintsView') {
            push(fingerPrintsViewFlickable, StackView.PushTransition)
        }
    }

    function goToFidoCredentialsView() {
        if (currentItem.objectName !== 'fidoCredentialsView') {
            push(fidoCredentialsViewFlickable, StackView.PushTransition)
        }
    }

    function goToNewFingerPrintView() {
        if (currentItem.objectName !== 'newFingerPrintView') {
            push(newFingerPrintViewFlickable, StackView.PushTransition)
        }
    }

    function goToOneTimePasswordView() {
        if (currentItem.objectName !== 'oneTimePasswordView') {
            clearAndPush(yubiKeyOneTimePasswordView, StackView.Immediate)
        }
    }

    function goToApplicationsView() {
        if (currentItem.objectName !== 'applicationsFlickable') {
            push(applicationsFlickable, StackView.PushTransition)
        }
    }

    function goToNewCredential() {
        if (currentItem.objectName !== 'newCredentialView') {
            push(newCredentialView.createObject(app, {
                                                    "manualEntry": true
                                                }), StackView.Immediate)
        }
    }

    function goToNewCredentialScan(credential) {
        if (currentItem.objectName !== 'newCredentialView') {
            push(newCredentialView.createObject(app, {
                                                    "credential": credential,
                                                    "manualEntry": false
                                                }), StackView.Immediate)
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

    function goToCustomReader() {
        if (currentItem.objectName !== 'customReaderView') {
            push(customReaderView, StackView.PushTransition)
        }
    }

    function confirm(options) {
        var popup = confirmationPopup.createObject(app, options)
        popup.open()
    }

    function confirmInput(options) {
        var popup = confirmationInputPopup.createObject(app, options)
        popup.open()
    }

    function confirmFidoReset(options) {
        var popup = confirmationResetPopup.createObject(app, options)
        popup.open()
    }

    function waitForYubiKey(options) {
        var popup = waitForYubiKeyPopup.createObject(app, options)
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
        case 'open_win_fido':
            return qsTr('Failed to connect, FIDO access requires running as admin')
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
        id: yubiKeyWebAuthnView
        WebAuthnView {
        }
    }

    Component {
        id: fingerPrintsViewFlickable
        FingerPrintsView {
        }
    }

    Component {
        id: fidoCredentialsViewFlickable
        FidoCredentialsView {
        }
    }

    Component {
        id: newFingerPrintViewFlickable
        NewFingerPrintView {
        }
    }

    Component {
        id: yubiKeyOneTimePasswordView
        OneTimePasswordView {
        }
    }

    Component {
        id: applicationsFlickable
        ApplicationsView {
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
        id: confirmationInputPopup
        ConfirmationInputPopup {
        }
    }

    Component {
        id: confirmationResetPopup
        ResetFidoPopup {
        }
    }

    Component {
        id: waitForYubiKeyPopup
        WaitForKeyPopup {
        }
    }

    Component {
        id: snackBarComponent
        SnackBar {
        }
    }

}
