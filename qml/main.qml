import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2

ApplicationWindow {

    id: app

    width: 360
    height: 498
    minimumWidth: 360
    minimumHeight: 498
    visible: true

    readonly property string yubicoGreen: "#9aca3c"
    readonly property string yubicoBlue: "#284c61"
    readonly property string yubicoWhite: "#FFFFFF"
    readonly property string yubicoGrey: "#939598"

    readonly property string defaultDark: "#303030"
    readonly property string defaultDarkLighter: "#383838"
    readonly property string defaultDarkOverlay: "#444444"
    readonly property string defaultDarkSelection: "#444444"

    readonly property string defaultLight: "#fafafa"
    readonly property string defaultLightDarker: "#ffffff"
    readonly property string defaultLightOverlay: "#bbbbbb"
    readonly property string defaultLightSelection: "#eeeeee"

    Material.theme: Material.System
    Material.primary: yubicoGreen
    Material.accent: yubicoBlue

    EntriesModel {
        id: entries
    }

    header: StyledToolBar {
        id: toolBar
    }

    function enableLogging(logLevel) {
        yubiKey.enableLogging(logLevel, null)
    }
    function enableLoggingToFile(logLevel, logFile) {
        yubiKey.enableLogging(logLevel, logFile)
    }
    function disableLogging() {
        yubiKey.disableLogging()
    }

    function isDark() {
        return app.Material.theme === Material.Dark
    }

    function toggleTheme() {
        if (isDark()) {
            app.Material.theme = Material.Light
        } else {
            app.Material.theme = Material.Dark
        }
    }

    function goToSettings() {
        if (stackView.currentItem.objectName !== 'settingsView') {
            stackView.push(settingsView, StackView.Immediate)
        }
    }

    function goToNoYubiKeyView() {
        if (stackView.currentItem.objectName !== 'noYubiKeyView') {
            stackView.push(noYubiKeyView, StackView.Immediate)
        }
    }

    function goToCredentials() {
        if (stackView.currentItem.objectName !== 'credentialsView') {
            stackView.push(credentialsView, StackView.Immediate)
        }
    }

    function goToAddCredential() {
        if (stackView.currentItem.objectName !== 'newCredentialView') {
            stackView.push(newCredentialView, StackView.Immediate)
        }
    }

    YubiKeyPoller {
        id: yubiKeyPoller
    }

    YubiKey {
        id: yubiKey
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: credentialsView
        focus: true
        onCurrentItemChanged: {
            if (currentItem) {
                currentItem.forceActiveFocus()
            }
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
