import Qt.labs.platform 1.1
import QtQml 2.12
import QtQuick 2.9

SystemTrayIcon {

    function showWindow() {
        app.hide();
        app.show();
        raise();
        requestActivate();
    }

    visible: settings.closeToTray
    icon.source: Qt.platform.os == "osx" ? "../images/menubaricon.png" : "../images/windowicon.png"
    icon.mask: Qt.platform.os == "osx"
    onActivated: {
        if (reason === SystemTrayIcon.DoubleClick)
            showWindow();
        else
            sysTrayInstantiator.model = getFavoriteEntries();

    }

    menu: Menu {
        id: sysTrayMenu

        Instantiator {
            id: sysTrayInstantiator

            model: getFavoriteEntries()
            onObjectAdded: sysTrayMenu.insertItem(index, object)
            onObjectRemoved: sysTrayMenu.removeItem(object)

            delegate: MenuItem {
                text: credential.issuer ? credential.issuer + " (" + credential.name + ")" : credential.name
                onTriggered: calculateFavorite(credential, text)
            }

        }

        MenuSeparator {
            visible: sysTrayInstantiator.model.count > 0
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
