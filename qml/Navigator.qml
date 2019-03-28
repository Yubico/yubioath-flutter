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
        id: multipleYubiKeysView
        MultipleYubiKeysView {
        }
    }

    Component {
        id: newCredentialView
        NewCredentialView {
        }
    }
}
