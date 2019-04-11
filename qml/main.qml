import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import Qt.labs.settings 1.0
import QtQuick.Window 2.2

ApplicationWindow {

    id: app

    width: 360
    height: 536
    minimumWidth: 360
    minimumHeight: 536
    visible: true

    readonly property string yubicoGreen: "#9aca3c"
    readonly property string yubicoBlue: "#284c61"
    readonly property string yubicoWhite: "#ffffff"
    readonly property string yubicoGrey: "#939598"
    readonly property string yubicoRed: "#d32f2f"

    readonly property string defaultDark: "#303030"
    readonly property string defaultDarkLighter: "#383838"
    readonly property string defaultDarkOverlay: "#444444"
    readonly property string defaultDarkSelection: "#444444"
    readonly property string defaultDarkForeground: "#fafafa"

    readonly property string defaultLight: "#fafafa"
    readonly property string defaultLightDarker: "#ffffff"
    readonly property string defaultLightOverlay: "#bbbbbb"
    readonly property string defaultLightSelection: "#eeeeee"
    readonly property string defaultLightForeground: "#565656"

    property var currentCredentialCard

    Material.theme: getTheme()
    Material.primary: yubicoGreen
    Material.accent: yubicoGreen
    Material.foreground: isDark(
                             ) ? defaultDarkForeground : defaultLightForeground

    header: StyledToolBar {
        id: toolBar
    }

    // Don't refresh credentia ls when window is minimized or hidden
    // See http://doc.qt.io/qt-5/qwindow.html#Visibility-enum
    property bool isInForeground: visibility != 3 && visibility != 0

    Component.onCompleted: {
        if (settings.closeToTray && settings.hideOnLaunch) {
            hide()
        }
        updateTrayVisibility()
        ensureValidWindowPosition()
    }

    Component.onDestruction: saveScreenLayout()

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

    function setTheme(theme) {
        var _theme = theme.toLowerCase()
        if (_theme === "dark") {
            setDark()
        } else if (_theme === "light") {
            setLight()
        } else if (_theme === "auto") {
            setAuto()
        }
    }

    function setDark() {
        app.Material.theme = Material.Dark
        Material.foreground = defaultDarkForeground
        settings.theme = "dark"
    }

    function setLight() {
        app.Material.theme = Material.Light
        Material.foreground = defaultLightForeground
        settings.theme = "light"
    }

    function setAuto() {
        if (Material.System === Material.Dark) {
            setDark()
        } else {
            setLight()
        }
        settings.theme = "auto"
    }

    function getTheme() {
        if (settings.theme === "dark") {
            return Material.Dark
        } else if (settings.theme === "light") {
            return Material.Light
        } else if (settings.theme === "auto") {
            return Material.System
        }
        return Material.System
    }

    function toggleTheme() {
        if (isDark()) {
            setLight()
        } else {
            setDark()
        }
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
        SysTrayIcon.visible = settings.closeToTray
        // When the tray option is enabled, closing the last window
        // doesn't actually close the application.
        application.quitOnLastWindowClosed = !settings.closeToTray
    }
    // This information is stored in the system registry on Windows,
    // and in XML preferences files on macOS. On other Unix systems,
    // in the absence of a standard, INI text files are used.
    // See http://doc.qt.io/qt-5/qml-qt-labs-settings-settings.html#details
    Settings {
        id: settings

        property bool otpMode
        property bool slot1inUse
        property bool slot2inUse
        property int slot1digits
        property int slot2digits

        property bool closeToTray
        property bool hideOnLaunch

        property var theme

        // Keep track of window and desktop dimensions.
        property alias width: app.width
        property alias height: app.height
        property alias x: app.x
        property alias y: app.y
        property int desktopAvailableWidth
        property int desktopAvailableHeight

        onCloseToTrayChanged: updateTrayVisibility()

        onOtpModeChanged: clearEntriesAndCalculateAll()
        onSlot1inUseChanged: clearEntriesAndCalculateAll()
        onSlot1digitsChanged: clearEntriesAndCalculateAll()
        onSlot2inUseChanged: clearEntriesAndCalculateAll()
        onSlot2digitsChanged: clearEntriesAndCalculateAll()

        function clearEntriesAndCalculateAll() {
            entries.clear()
            yubiKeyPoller.nextCalculateAll = 0
        }
    }

    EntriesModel {
        id: entries
    }

    ClipBoard {
        id: clipBoard
    }

    YubiKeyPoller {
        id: yubiKeyPoller
    }

    YubiKey {
        id: yubiKey
    }

    Navigator {
        id: navigator
        anchors.fill: parent
        focus: true
        Keys.forwardTo: toolBar.searchField
    }
}
