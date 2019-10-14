import QtQuick 2.9
import Qt.labs.platform 1.1
import QtQml 2.12

SystemTrayIcon {
    visible: settings.closeToTray
    icon.source: "../images/windowicon.png"
    onActivated: {
        if(reason === SystemTrayIcon.DoubleClick) {
            showWindow()
        } else {
            sysTrayInstantiator.model = getFavoriteEntries()
        }
    }

    function showWindow() {
        app.hide()
        app.show()
        raise()
        requestActivate()
    }

    menu: Menu {
        id: sysTrayMenu

        Instantiator {
            id: sysTrayInstantiator
            model: getFavoriteEntries()
            onObjectAdded: sysTrayMenu.insertItem(index, object)
            onObjectRemoved: sysTrayMenu.removeItem(object)
            delegate: MenuItem {
                text: credential.issuer ?  credential.issuer + " (" + credential.name + ")" : credential.name
                onTriggered: calculateFavorite(credential, text)
            }
        }

        MenuSeparator {
        }

        MenuItem {
            text: qsTr("Show Yubico Authenticator")
            onTriggered: showWindow()
        }

        MenuSeparator {
        }

        MenuItem {
            text: qsTr("Quit")
            onTriggered: Qt.quit()
        }
    }
}
