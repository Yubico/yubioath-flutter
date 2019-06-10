import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Pane {
    id: pane
    padding: entries.count === 0 ? 32 : 0
    topPadding: entries.count === 0 ? 64 : 0
    objectName: 'credentialsView'

    property string title: ""

    function filteredCredentials() {
        if (entries !== null && toolBar.searchField.text.length > 0) {
            var filteredEntries = entriesComponent.createObject(app, {

                                                                })
            for (var i = 0; i < entries.count; i++) {
                var entry = entries.get(i)
                if (entry !== null && entry !== undefined) {
                    if (entry.credential.key.toLowerCase().indexOf(
                                toolBar.searchField.text.toLowerCase(
                                    )) !== -1) {
                        filteredEntries.append(entry)
                    }
                }
            }
            return filteredEntries
        }
        return entries
    }

    Component {
        id: entriesComponent
        EntriesModel {
        }
    }

    MouseArea {
        onClicked: grid.currentIndex = -1
        anchors.fill: parent
        enabled: entries.count > 0
    }

    NoCredentialsSection {
        visible: entries.count === 0 && yubiKey.currentDeviceValidated
                 && !!yubiKey.currentDevice
        enabled: visible
    }

    NoResultsSection {
        visible: entries.count > 0 && yubiKey.currentDeviceValidated
                 && filteredCredentials().count === 0 && !!yubiKey.currentDevice
        enabled: visible
    }

    NoYubiKeySection {
        visible: yubiKey.availableDevices.length === 0
        enabled: visible
    }

    GridView {
        id: grid
        displayMarginBeginning: 80
        displayMarginEnd: 80
        ScrollBar.vertical: ScrollBar {
            width: 8
        }
        width: {
            var w = (parent.width - (Math.min(
                                         model.count, Math.floor(
                                             parent.width / cellWidth)) * cellWidth)) / 2
            leftMargin = w >= 180 ? 0 : w
            return parent.width
        }
        height: (Math.min(model.count,
                          Math.floor(parent.height / cellHeight)) * cellHeight)
                || cellHeight
        anchors.top: parent.top
        onCurrentItemChanged: app.currentCredentialCard = currentItem
        visible: entries.count > 0
        enabled: visible
        keyNavigationWraps: false
        flickableDirection: Flickable.VerticalFlick
        model: filteredCredentials()
        cellWidth: 362
        cellHeight: 82
        delegate: CredentialCard {
            credential: model.credential
            code: model.code
        }
        flickableChildren: MouseArea {
            anchors.fill: parent
            onClicked: grid.currentIndex = -1
        }
        focus: visible
        Component.onCompleted: currentIndex = -1
        KeyNavigation.tab: toolBar.searchField
        KeyNavigation.up: toolBar.searchField
        Keys.onEscapePressed: {
            currentIndex = -1
        }
        Keys.onReturnPressed: {
            if (currentIndex !== -1) {
                currentItem.calculateCard(true)
            }
        }
        Keys.onDeletePressed: {
            if (currentIndex !== -1) {
                currentItem.deleteCard()
            }
        }
    }
}
