import QtQuick 2.5
import QtQuick.Controls 1.4

MenuBar {

    property bool slotMode
    property bool hasDevice

    signal openAddCredential
    signal openAbout
    signal openReset
    signal openSettings
    signal openSetPassword

    Menu {
        title: qsTr("\&File")
        MenuItem {
            text: qsTr("\&Add credential...")
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
            text: qsTr("\&Exit")
            onTriggered: Qt.quit()
            shortcut: StandardKey.Quit
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
