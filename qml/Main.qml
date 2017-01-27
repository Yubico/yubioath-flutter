import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.2

ApplicationWindow {
    visible: true
    title: qsTr("YubiKey Authenticator")
    flags: Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowCloseButtonHint | Qt.WindowMinimizeButtonHint | Qt.MSWindowsFixedSizeDialogHint
    menuBar: MenuBar {

        Menu {
            title: qsTr("File")
            MenuItem {
                text: qsTr("Exit")
                onTriggered: Qt.quit()
            }
        }

        Menu {
            title: qsTr("Help")
            MenuItem {
                text: qsTr("About YubiKey Manager")
                onTriggered: aboutPage.show()
            }
        }
    }

    AboutPage {
        id: aboutPage
    }

    // @disable-check M301
    YubiKey {
        id: yk
        onError: {
            errorBox.text = traceback;
            errorBox.open()
        }
    }

    MessageDialog {
        id: errorBox
        icon: StandardIcon.Critical
        title: qsTr("Error!")
        text: ""
        standardButtons: StandardButton.Ok
    }

    Timer {
        id: timer
        triggeredOnStart: true
        interval: 500
        repeat: true
        running: true
        onTriggered: yk.refresh()
    }

    Loader {
        id: loader
        sourceComponent: yk.hasDevice ? deviceInfo : message
    }

    Component {
        id: message
        Text {
            width: 200
            height: 200
            text: if (yk.nDevices == 0) {
                      qsTr("No YubiKey detected")
                  } else if (yk.nDevices == 1) {
                      qsTr("Connecting to YubiKey...")
                  } else {
                      qsTr("Multiple YubiKeys detected!")
                  }
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Component {
        id: deviceInfo

        DeviceInfo {
            device: yk
        }
    }
}
