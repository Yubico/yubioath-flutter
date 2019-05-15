import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ScrollView {
    id: pane
    padding: entries.count === 0 ? 32 : 0
    topPadding: entries.count === 0 ? 64 : 0
    objectName: 'credentialsView'

    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical: ScrollBar {
        interactive: true
        width: 5
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
    }

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

    NoCredentialsSection {
        visible: entries.count === 0 && yubiKey.currentDeviceValidated
                 && !!yubiKey.currentDevice
    }

    NoResultsSection {
        visible: entries.count > 0 && yubiKey.currentDeviceValidated
                 && filteredCredentials().count === 0 && !!yubiKey.currentDevice
    }

    NoYubiKeySection {
        visible: yubiKey.availableDevices.length !== 1
    }

    GridView {
        id: grid
        displayMarginBeginning: 80
        anchors.horizontalCenter: parent.horizontalCenter
        width: (Math.min(model.count,
                         Math.floor(parent.width / cellWidth)) * cellWidth)
               || cellWidth
        anchors.bottom: parent.bottom
        anchors.top: parent.top
        onCurrentItemChanged: app.currentCredentialCard = currentItem
        visible: entries.count > 0
        keyNavigationWraps: false
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: true
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
        focus: true
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
