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

    width: 270
    height: 582 // (idealCellHeight * x) + 46
    minimumWidth: 270
    minimumHeight: 381 // (idealCellHeight * x) + 46
    visible: false

    flags: Qt.Window | Qt.WindowFullscreenButtonHint | Qt.WindowTitleHint
           | Qt.WindowSystemMenuHint | Qt.WindowMinMaxButtonsHint
           | Qt.WindowCloseButtonHint | Qt.WindowFullscreenButtonHint

    readonly property int dynamicWidth: 768
    readonly property int dynamicWidthSmall: 380
    readonly property int dynamicMargin: 32
    readonly property int dynamicMarginSmall: 16

    readonly property string yubicoBlue: "#325f74"
    readonly property string yubicoGreen: isDark() ? "#b1cf77" : "#325f74"
    readonly property string yubicoWhite: "#ffffff"
    readonly property string yubicoRed: isDark() ? "#cf6679" : "#bf2029"

    property string primaryColor: isDark() ? "#ffffff" : "#2a2a2a"
    property string fullContrast: isDark() ? "#000000" : "#ffffff"

    readonly property string defaultBackground: isDark() ? "#303030" : "#ffffff"
    readonly property string defaultElevated: isDark() ? "#383838" : "#ffffff"
    readonly property string defaultHovered: isDark() ? "#424242" : "#eeeeee"
    readonly property string defaultImageOverlay: isDark() ? "#565656" : "#dddddd"
    readonly property string defaultForeground: isDark() ? "#fafafa" : "#565656"

    property string formUnderline: isDark() ? "#737373" : "#d8d8d8"
    property string formText: isDark() ? "#f0f0f0" : "#606060"
    property string formPlaceholderText: isDark() ? "#808080" : "#b0b0b0"
    property string formImageOverlay: isDark() ? "#d8d8d8" : "#727272"
    property string formStepBackground: isDark() ? "#565656" : "#bbbbbb"
    property string formHighlightItem: isDark() ? "#4a4a4a" : "#e9e9e9"
    property string formButtonBorder: isDark() ? "#5f6368" : "#dadce0"

    property string toolTipForeground: isDark() ? "#fafafa" : "#fbfbfb"
    property string toolTipBackground: isDark() ? "#4a4a4a" : "#7f7f7f"

    property string iconFavorite: "#f7bd0c"
    property string snackBarInfoBg: isDark() ? "#bfbfbf" : "#404040"

    property var fullEmphasis: 1.0
    property var highEmphasis: 0.87
    property var lowEmphasis: 0.60
    property var disabledEmphasis: 0.38

    property var cardSelectedEmphasis: 0.08
    property var cardHoveredEmphasis: 0.05
    property var cardNormalEmphasis: 0

    property bool showDeviceConfiguration: false

    Material.theme: settings.theme
    Material.primary: yubicoGreen
    Material.accent: isDark() ? yubicoGreen : "#9aca3c"
    Material.foreground: defaultForeground
    Material.background: defaultBackground

    header: StyledToolBar {
        id: toolBar
    }

    NavigationDrawer {
        id: drawer
    }

    // Don't refresh credentials when window is minimized or hidden
    // See http://doc.qt.io/qt-5/qwindow.html#Visibility-enum
    property bool isInForeground: visibility !== 3 && visibility !== 0
    onIsInForegroundChanged: {
        (poller.running = isInForeground || settings.closeToTray)
    }
    Component.onCompleted: {
        updateTrayVisibility()
        ensureMinimumWindowSize()
        ensureValidWindowPosition()
        restoreLastView()
        app.visible = !(settings.closeToTray && settings.hideOnLaunch)
    }

    Component.onDestruction: saveScreenLayout()

    FontLoader {
        id: robotoRegular;
        source: "../fonts/Roboto-Regular.ttf"
    }

    FontLoader {
        id: robotoBold;
        source: "../fonts/Roboto-Bold.ttf"
    }

    FontLoader {
        id: robotoItalic;
        source: "../fonts/Roboto-Italic.ttf"
    }

    FontLoader {
        id: robotoMedium;
        source: "../fonts/Roboto-Medium.ttf"
    }

    FontLoader {
        id: robotoLight;
        source: "../fonts/Roboto-Light.ttf"
    }

    font.family: robotoRegular.name

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

    function restoreLastView() {
        if(settings.activeView == 'yubiKeyView') {
            navigator.goToYubiKey()
        }
        // Defaults to "authenticatorView"
    }

    function saveScreenLayout() {
        settings.desktopAvailableWidth = Screen.desktopAvailableWidth
        settings.desktopAvailableHeight = Screen.desktopAvailableHeight
    }

    function ensureMinimumWindowSize() {
        app.width = width < minimumWidth ? minimumWidth : width
        app.height = height < minimumHeight ? minimumHeight : height
    }

    function ensureValidWindowPosition() {
        // If we have the same desktop dimensions as last time, use the saved position.
        // If not, put the window in the middle of the screen.
        var savedScreenLayout = (settings.desktopAvailableWidth === Screen.desktopAvailableWidth)
                && (settings.desktopAvailableHeight === Screen.desktopAvailableHeight)
        app.x = (savedScreenLayout) ? settings.x : Screen.width / 2 - app.width / 2
        app.y = (savedScreenLayout) ? settings.y : Screen.height / 2 - app.height / 2

        function isWindowPositionInsideSomeMonitor() {
            for (var i = 0; i < monitorAreas.length; i++)  {
                var xMin = monitorAreas[i].xMin
                var xMax = monitorAreas[i].xMax
                var yMin = monitorAreas[i].yMin
                var yMax = monitorAreas[i].yMax

                if (app.x > xMin && app.x < xMax) {
                    if (app.y > yMin && app.y < yMax) {
                        return true
                    }
                }
            }
            return false
        }

        // If app.x and app.y are outside of the available screen geometry,
        // put the app in the middle of the screen.
        if (!isWindowPositionInsideSomeMonitor() && (Qt.platform.os == "windows")) {
            app.x = Screen.width / 2 - app.width / 2
            app.y = Screen.height / 2 - app.height / 2
        }

    }

    function updateTrayVisibility() {
        // When the tray option is enabled, closing the last window
        // doesn't actually close the application.
        application.quitOnLastWindowClosed = !settings.closeToTray
    }

    function calculateFavorite(credential, text) {
        if (credential && credential.touch) {
            sysTrayIcon.showMessage(
                        qsTr("Touch required"),
                        qsTr("Touch your YubiKey now to generate security code."),
                        SystemTrayIcon.NoIcon)
        }
        if (settings.otpMode) {
            yubiKey.otpCalculate(credential, function (resp) {
                if (resp.success) {
                    clipBoard.push(resp.code.value)
                    sysTrayIcon.showMessage(
                                qsTr("Copied to clipboard"),
                                "The code for " + text + " is now in the clipboard.",
                                SystemTrayIcon.NoIcon)
                } else {
                    sysTrayIcon.showMessage(
                                "Error",
                                "calculate failed: " + resp.error_id,
                                SystemTrayIcon.NoIcon)
                    console.log("calculate failed:", resp.error_id)
                }
            })
        } else {
            yubiKey.calculate(credential, function (resp) {
                if (resp.success) {
                    clipBoard.push(resp.code.value)
                    sysTrayIcon.showMessage(
                                qsTr("Copied to clipboard"),
                                "The code for " + text + " is now in the clipboard.",
                                SystemTrayIcon.NoIcon)
                } else {
                    sysTrayIcon.showMessage(
                                qsTr("Error"),
                                "calculate failed: " + resp.error_id,
                                SystemTrayIcon.NoIcon)
                    console.log("calculate failed:", resp.error_id)
                }
            })
        }

    }

    function colorizeMatch(string, query) {
        return string.replace(escapeRegExp(query.trim(), "gi"), "<span style=\"background-color:'#ffeb3b';color:'#000000';\">$&</span>") + " "
    }

    function escapeRegExp(string, flags) {
      return RegExp(string.replace(/[.*+\-?^${}()|[\]\\]/g, '\\$&').replace(/\s+/g, "|"), flags)
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
        id: shortcutGoToAuthenticator
        property string description: "Go to Authenticator"
        sequence: "Ctrl+1"
        onActivated: navigator.goToAuthenticator()
        context: Qt.ApplicationShortcut
        enabled: yubiKey.currentDeviceEnabled("OATH")
    }

    Shortcut {
        id: shortcutGoToYubiKey
        property string description: "Go to Configure YubiKey"
        sequence: "Ctrl+2"
        onActivated: navigator.goToYubiKey()
        context: Qt.ApplicationShortcut
    }

    Shortcut {
        id: shortcutGoToSettings
        property string description: "Go to Settings"
        sequence: "Ctrl+3"
        onActivated: navigator.goToSettings()
        context: Qt.ApplicationShortcut
    }

    Shortcut {
        sequence: StandardKey.Preferences
        onActivated: navigator.goToSettings()
        context: Qt.ApplicationShortcut
    }

    Shortcut {
        id: shortcutGoToAbout
        property string description: "Go to About"
        sequence: "Ctrl+4"
        onActivated: navigator.goToAbout()
        context: Qt.ApplicationShortcut
    }

    Shortcut {
        id: shortcutCopy
        property string description: "Copy account"
        sequence: StandardKey.Copy
        enabled: navigator.isInAuthenticator() && navigator.hasSelectedOathCredential()
        onActivated: navigator.oathCopySelectedCredential()
    }

    Shortcut {
        id: shortcutDelete
        property string description: "Delete account"
        sequence: StandardKey.Delete
        enabled: navigator.isInAuthenticator() && navigator.hasSelectedOathCredential()
        onActivated: navigator.oathDeleteSelectedCredential()
    }

    Shortcut {
        id: shortcutToggleFavorite
        property string description: "Toggle favorite"
        sequence: "Ctrl+D"
        enabled: navigator.isInAuthenticator() && navigator.hasSelectedOathCredential()
        onActivated: navigator.oathToggleFavoriteSelectedCredential()
    }

    Shortcut {
        id: shortcutScanQR
        property string description: "Scan QR code"
        sequence: "Shift+Ctrl+O"
        enabled: navigator.isInAuthenticator() && !!yubiKey.currentDevice
        onActivated: yubiKey.scanQr()
    }

    Shortcut {
        id: shortcutAddAccount
        property string description: "Add account"
        sequence: StandardKey.Open
        enabled: navigator.isInAuthenticator() && !!yubiKey.currentDevice
        onActivated: navigator.goToNewCredential()
    }

    Shortcut {
        id: shortcutFind
        property string description: "Find account"
        enabled: navigator.isInAuthenticator() && !!yubiKey.currentDevice
        sequence: StandardKey.Find
        onActivated: toolBar.searchField.forceActiveFocus()
    }

    Shortcut {
        id: shortcutQuit
        property string description: "Quit application"
        sequence: "Ctrl+Q"
        context: Qt.ApplicationShortcut
        onActivated: Qt.quit()
    }

    Shortcut {
        id: shortcutClose
        property string description: "Close application window"
        sequence: StandardKey.Close
        onActivated: app.close()
        context: Qt.ApplicationShortcut
    }

    Shortcut {
        id: shortcutFullScreen
        property string description: "Toggle full screen"
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

        // Can be 0 (off), 6, 7 or 8
        property int slot1digits
        property int slot2digits

        property bool otpMode

        property bool useCustomReader
        property string customReaderName

        property bool closeToTray
        property bool hideOnLaunch
        property bool requireTouch

        property int theme: Material.System

        // Keep track of window and desktop dimensions.
        property alias width: app.width
        property alias height: app.height
        property alias x: app.x
        property alias y: app.y

        property int desktopAvailableWidth
        property int desktopAvailableHeight

        property var favorites: []

        property string activeView

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
        running: app.isInForeground || settings.closeToTray
        onTriggered: {
            settings.useCustomReader ? yubiKey.pollCustomReader() : yubiKey.pollUsb()
            if (settings.otpMode) {
                settings.useCustomReader = false
            }

            if (navigator.isInAuthenticator()) {
                if (yubiKey.timeToCalculateAll()) {
                    yubiKey.oathCalculateAllOuter()
                }
            }

        }
    }

    YubiKey {
        id: yubiKey
    }

    SystemTray {
        id: sysTrayIcon
    }

    Navigator {
        id: navigator
        anchors.fill: parent
        focus: true
    }
}
