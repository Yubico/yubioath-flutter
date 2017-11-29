import QtQuick 2.5
import QtQuick.Controls 1.4

MenuBar {

    property bool slotMode
    property bool hasDevice

    property bool enableGenerate

    signal openAddCredential
    signal openAbout
    signal openReset
    signal openSettings
    signal openSetPassword

    Menu {
        title: qsTr("\&File")
        MenuItem {
            text: qsTr("\&Scan QR code...")
            enabled: hasDevice
            onTriggered: scanQr()
            shortcut: StandardKey.Open
        }
        MenuItem {
            text: qsTr("\&New credential...")
            enabled: hasDevice
            onTriggered: openAddCredential()
            shortcut: StandardKey.New
        }
        MenuItem {
            text: qsTr("Set password...")
            enabled: !slotMode && hasDevice
            onTriggered: openSetPassword()
        }
        MenuItem {
            text: qsTr("Reset...")
            enabled: !slotMode && hasDevice
            onTriggered: openReset()
        }
        MenuItem {
            text: qsTr("\&Settings")
            onTriggered: openSettings()
        }
        MenuItem {
            text: qsTr("E\&xit")
            onTriggered: Qt.quit()
            shortcut: StandardKey.Quit
        }
    }

    Menu {
        title: qsTr("\&Edit")

        MenuItem {
            text: qsTr("\&Copy to clipboard")
            shortcut: StandardKey.Copy
            enabled: (getSelected() != null) && (getSelected().code != null)
            onTriggered:copy()
        }

        MenuItem {
            enabled: enableGenerate
            text: qsTr("\&Generate code")
            shortcut: "Space"
            onTriggered: generate(false)
        }

        MenuSeparator {
        }

        MenuItem {
            text: qsTr("\&Delete")
            shortcut: StandardKey.Delete
            enabled: (getSelected() != null)
            onTriggered: deleteCredential()
        }
    }

    Menu {
        title: qsTr("\&Help")
        MenuItem {
            text: qsTr("\&About Yubico Authenticator")
            onTriggered: openAbout()
        }
    }
}
