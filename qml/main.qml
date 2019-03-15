import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2

ApplicationWindow {

    id: app

    width: 360
    height: 496
    minimumWidth: 360
    minimumHeight: 144
    visible: true

    readonly property string yubicoGreen: "#9aca3c"
    readonly property string yubicoBlue: "#284c61"
    readonly property string yubicoWhite: "#FFFFFF"
    readonly property string yubicoGrey: "#939598"

    readonly property string defaultDark: "#303030"
    readonly property string defaultLight: "#FAFAFA"

    Material.theme: Material.System
    Material.primary: yubicoGreen
    Material.accent: yubicoBlue

    header: StyledToolBar {
        id: toolBar
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
            stackView.push(settingsView)
        }
    }

    function goToCredentials() {
        if (stackView.currentItem.objectName !== 'credentialsView') {
            stackView.push(credentialsView)
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: noYubiKeyView
    }

    Component {
        id: credentialsView
        CredentialsView {
            padding: 0
            topPadding: 8
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
}
