import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ScrollView {
    id: pane
    objectName: 'credentialsView'

    property var filtered: 0

    contentHeight: filteredCredentials().count > 0 ? grid.contentHeight : app.height - toolBar.height

    ScrollBar.vertical: ScrollBar {
        id: paneScrollBar
        width: 8
        anchors.top: pane.top
        anchors.right: pane.right
        anchors.bottom: pane.bottom
        hoverEnabled: true
        z: 2
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

    MouseArea {
        onClicked: grid.currentIndex = -1
        anchors.fill: parent
        enabled: entries.count > 0
    }

    NoCredentialsSection {
        visible: entries.count === 0 && !!yubiKey.currentDevice && yubiKey.currentDeviceValidated
        enabled: visible
    }

    NoResultsSection {
        visible: entries.count > 0 && !!yubiKey.currentDevice && yubiKey.currentDeviceValidated
                 && filteredCredentials().count === 0
        enabled: visible
    }

    NoYubiKeySection {
        visible: !yubiKey.availableDevices.some(dev => dev.selectable)
        enabled: visible
    }

    GridView {
        id: grid
        displayMarginBeginning: cellHeight
        displayMarginEnd: cellHeight
        width: (Math.min(model.count, Math.floor(parent.width / cellWidth)) * cellWidth) || cellWidth
        height: (Math.min(model.count, Math.floor((parent.height - toolBar.height) / cellHeight)) * cellHeight) || cellHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        onCurrentItemChanged: app.currentCredentialCard = currentItem
        visible: entries.count > 0
        enabled: visible
        keyNavigationWraps: false
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
        KeyNavigation.up: paneScrollBar.position === 0 ? toolBar.searchField : null
        interactive: false
        highlightFollowsCurrentItem: false
        Keys.onPressed: interactive = true
        Keys.onReleased: interactive = false
        Keys.onEscapePressed: currentIndex = -1
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
