import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import Qt.labs.settings 1.0
import Qt.labs.platform 1.1
import QtQuick.Window 2.2
import QtQml 2.12

ApplicationWindow {

    id: app

    width: 360
    height: 620
    minimumWidth: 360
    minimumHeight: 126
    visible: false

    flags: Qt.Window | Qt.WindowFullscreenButtonHint | Qt.WindowTitleHint
           | Qt.WindowSystemMenuHint | Qt.WindowMinMaxButtonsHint
           | Qt.WindowCloseButtonHint | Qt.WindowFullscreenButtonHint

    readonly property string yubicoGreen: "#9aca3c"
    readonly property string yubicoBlue: "#284c61"
    readonly property string yubicoWhite: "#ffffff"
    readonly property string yubicoGrey: "#939598"
    readonly property string yubicoRed: "#fd5552"

    readonly property string defaultDark: "#303030"
    readonly property string defaultDarkLighter: "#383838"
    readonly property string defaultDarkOverlay: "#4a4a4a"
    readonly property string defaultDarkForeground: "#fafafa"

    readonly property string defaultLight: "#f7f7f7"
    readonly property string defaultLightDarker: "#ffffff"
    readonly property string defaultLightOverlay: "#bbbbbb"
    readonly property string defaultLightForeground: "#565656"

    readonly property string defaultBackground: isDark() ? "#303030" : "#f7f7f7"

    property string formUnderline: isDark() ? "#737373" : "#d8d8d8"
    property string formLabel: isDark() ? "#c0c0c0" : "#a0a0a0"
    property string formText: isDark() ? "#f0f0f0" : "#7e7e7e"
    property string formPlaceholderText: isDark() ? "#808080" : "#d0d0d0"
    property string formDropShdaow: isDark() ? "#1f1f1f" : "#cbcbcb"
    property string formImageOverlay: isDark() ? "#d8d8d8" : "#727272"
    property string formTitleUnderline: isDark() ? "#424242" : "#f5f5f5"

    property string credentialCardCurrentItem: isDark() ? "#4a4a4a" : "#f0f0f0"
    property string credentialCardHovered: isDark() ? "#424242" : "#fbfbfb"
    property string credentialCardNormal: isDark() ? "#3e3e3e" : "#ffffff"

    property string iconButtonNormal: isDark() ? "#B7B7B7" : "#767676"
    property string iconButtonHovered: isDark() ? "#ffffff" : "#202020"

    property string toolTipForeground: app.isDark() ? "#fafafa" : "#f7f7f7"
    property string toolTipBackground: app.isDark() ? "#4a4a4a" : "#565656"

    property var currentCredentialCard

    Material.theme: settings.theme
    Material.primary: yubicoGreen
    Material.accent: yubicoGreen
    Material.foreground: isDark(
                             ) ? defaultDarkForeground : defaultLightForeground
    Material.background: defaultBackground
    header: StyledToolBar {
        id: toolBar
    }

    // Don't refresh credentials when window is minimized or hidden
    // See http://doc.qt.io/qt-5/qwindow.html#Visibility-enum
    property bool isInForeground: visibility != 3 && visibility != 0

    Component.onCompleted: {
        updateTrayVisibility()
        ensureValidWindowPosition()
    }

    Component.onDestruction: saveScreenLayout()

    function enableLogging(logLevel) {
        yubiKey.enableLogging(logLevel, null)
    }
    function enableLoggingToFile(logLevellogFile) {
        yubiKey.enableLogging(logLevel, logFile)
    }
    function disableLogging() {
        yubiKey.disableLogging()
    }

    function isDark() {
        return app.Material.theme === Material.Dark
    }

    function saveScreenLayout() {
        settings.desktopAvailableWidth = Screen.desktopAvailableWidth
        settings.desktopAvailableHeight = Screen.desktopAvailableHeight
    }

    function ensureValidWindowPosition() {
        // If we have the same desktop dimensions as last time, use the saved position.
        // If not, put the window in the middle of the screen.
        var savedScreenLayout = (settings.desktopAvailableWidth === Screen.desktopAvailableWidth)
                && (settings.desktopAvailableHeight === Screen.desktopAvailableHeight)
        app.x = (savedScreenLayout) ? settings.x : Screen.width / 2 - app.width / 2
        app.y = (savedScreenLayout) ? settings.y : Screen.height / 2 - app.height / 2
    }

    function updateTrayVisibility() {
        // When the tray option is enabled, closing the last window
        // doesn't actually close the application.
        app.visible = !(settings.closeToTray && settings.hideOnLaunch)
        application.quitOnLastWindowClosed = !settings.closeToTray
    }

    function calculateFavorite(credential, text) {
        if (credential && credential.touch) {
            sysTrayIcon.showMessage(
                        "Touch required",
                        "Touch your YubiKey now to generate code for protected credential.")
        }
        if (settings.otpMode) {
            yubiKey.otpCalculate(credential, function (resp) {
                if (resp.success) {
                    clipBoard.push(resp.code.value)
                    sysTrayIcon.showMessage(
                                "Copied to clipboard",
                                "The code for " + text + " is now in the clipboard.")
                } else {
                    navigator.snackBarError(resp.error_id)
                    console.log("calculate failed:", resp.error_id)
                }
            })
        } else {
            yubiKey.calculate(credential, function (resp) {
                if (resp.success) {
                    clipBoard.push(resp.code.value)
                    sysTrayIcon.showMessage(
                                "Copied to clipboard",
                                "The code for " + text + " is now in the clipboard.")
                } else {
                    navigator.snackBarError(navigator.getErrorMessage(
                                                resp.error_id))
                    console.log("calculate failed:", resp.error_id)
                }
            })
        }
    }

    function getFavoriteEntries() {
        var favs = entriesComponent.createObject(app, {
        })
        for (var i = 0; i < entries.count; i++) {
            var entry = entries.get(i)
            if (!!entry.credential && settings.favorites.includes(entry.credential.key)) {
                favs.append(entry)
            }
        }
        return favs
    }

    Shortcut {
        sequence: StandardKey.Copy
        enabled: !!currentCredentialCard
        onActivated: app.currentCredentialCard.calculateCard(true)
    }

    Shortcut {
        sequence: StandardKey.Delete
        enabled: !!currentCredentialCard
        onActivated: app.currentCredentialCard.deleteCard()
    }

    Shortcut {
        sequence: StandardKey.Open
        enabled: yubiKey.currentDeviceValidated
        onActivated: yubiKey.scanQr()
    }

    Shortcut {
        sequence: StandardKey.Preferences
        onActivated: navigator.goToSettings()
    }

    Shortcut {
        sequence: StandardKey.Quit
        context: Qt.ApplicationShortcut
        onActivated: Qt.quit()
    }

    Shortcut {
        sequence: StandardKey.Close
        onActivated: app.close()
        context: Qt.ApplicationShortcut
    }

    Shortcut {
        sequence: StandardKey.FullScreen
        onActivated: visibility = visibility
                     === Window.FullScreen ? Window.Windowed : Window.FullScreen
        context: Qt.ApplicationShortcut
    }

    // This information is stored in the system registry on Windows,
    // and in XML preferences files on macOS. On other Unix systems,
    // in the absence of a standard, INI text files are used.
    // See http://doc.qt.io/qt-5/qml-qt-labs-settings-settings.html#details
    Settings {
        id: settings

        property bool otpMode

        // Can be 0 (off), 6, 7 or 8
        property int slot1digits
        property int slot2digits

        property bool useCustomReader
        property string customReaderName

        property bool closeToTray
        property bool hideOnLaunch

        property int theme
        property string themeAccentColor

        // Keep track of window and desktop dimensions.
        property alias width: app.width
        property alias height: app.height
        property alias x: app.x
        property alias y: app.y

        property int desktopAvailableWidth
        property int desktopAvailableHeight

        property var favorites: []

        onCloseToTrayChanged: updateTrayVisibility()
        onThemeChanged: {
            app.Material.theme = theme
        }
    }

    Component {
        id: entriesComponent
        EntriesModel {
        }
    }

    EntriesModel {
        id: entries
    }

    ClipBoard {
        id: clipBoard
    }

    Timer {
        id: poller
        triggeredOnStart: true
        interval: 1000
        repeat: true
        running: app.isInForeground
        onTriggered: yubiKey.poll()
    }

    YubiKey {
        id: yubiKey
    }

    SystemTrayIcon {
        id: sysTrayIcon
        visible: settings.closeToTray
        iconSource: "qrc:/images/windowicon.png"
        onActivated: sysTrayInstantiator.model = getFavoriteEntries()

        menu: Menu {
            id: sysTrayMenu

            Instantiator {
                id: sysTrayInstantiator
                model: getFavoriteEntries()
                onObjectAdded: sysTrayMenu.insertItem(index, object)
                onObjectRemoved: sysTrayMenu.removeItem(object)

                delegate: MenuItem {
                    text: {
                        if (credential.issuer) {
                            return credential.issuer + " (" + credential.name + ")"
                        } else {
                            return credential.name
                        }
                    }
                    onTriggered: calculateFavorite(credential, text)
                }
            }

            MenuSeparator {
            }

            MenuItem {
                text: qsTr("Show credentials")
                onTriggered: {
                    show()
                    raise()
                    requestActivate()
                }
            }

            MenuSeparator {
            }

            MenuItem {
                text: qsTr("Quit")
                onTriggered: Qt.quit()
            }
        }
    }

    Navigator {
        id: navigator
        anchors.fill: parent
        focus: true
        Keys.forwardTo: toolBar.searchField
    }
}
