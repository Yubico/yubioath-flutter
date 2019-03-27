import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import Qt.labs.settings 1.0
import QtQuick.Window 2.2

ApplicationWindow {

    id: app

    width: 360
    height: 552
    minimumWidth: 360
    minimumHeight: 552
    visible: true

    readonly property string yubicoGreen: "#9aca3c"
    readonly property string yubicoBlue: "#284c61"
    readonly property string yubicoWhite: "#ffffff"
    readonly property string yubicoGrey: "#939598"

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

    Component.onCompleted: ensureValidWindowPosition()
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
        app.Material.theme = Material.System
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
        console.log("saving layout")
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

    // This information is stored in the system registry on Windows,
    // and in XML preferences files on macOS. On other Unix systems,
    // in the absence of a standard, INI text files are used.
    // See http://doc.qt.io/qt-5/qml-qt-labs-settings-settings.html#details
    Settings {
        id: settings
        property bool slotMode
        property bool slot1
        property bool slot2
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
