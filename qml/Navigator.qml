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

    function goToSettings() {
        if (currentItem.objectName !== 'settingsView') {
            push(settingsView, StackView.Immediate)
        }
    }

    function goToNoYubiKeyView() {
        if (currentItem.objectName !== 'noYubiKeyView') {
            push(noYubiKeyView, StackView.Immediate)
        }
    }

    function goToCredentials() {
        if (currentItem.objectName !== 'credentialsView') {
            push(credentialsView, StackView.Immediate)
        }
    }

    function goToNewCredentialManual() {
        if (!isAtNewCredential()) {
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

    function isAtNewCredential() {
        return currentItem.objectName === 'newCredentialView'
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
