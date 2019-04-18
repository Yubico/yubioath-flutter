import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Pane {
    padding: entries.count === 0 ? 50 : 0
    topPadding: entries.count === 0 ? 50 : 16
    objectName: 'credentialsView'
    Material.background: getBackgroundColor()

    property string title: ""

    function getBackgroundColor() {
        if (isDark()) {
            return entries.count === 0 ? defaultDarkLighter : defaultDark
        } else {
            return entries.count === 0 ? defaultLight : defaultLight
        }
    }

    function filteredCredentials() {
        if (entries !== null && toolBar.searchField.text.length > 0) {
            var filteredEntries = entriesComponent.createObject(app, {

                                                                })
            for (var i = 0; i < entries.count; i++) {
                var entry = entries.get(i)
                if (entry.credential.key.toLowerCase().indexOf(
                            toolBar.searchField.text.toLowerCase()) !== -1) {
                    filteredEntries.append(entry)
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
        visible: entries.count === 0
    }

    GridView {
        id: grid
        anchors.horizontalCenter: parent.horizontalCenter
        width: (Math.min(model.count,
                         Math.floor(parent.width / cellWidth)) * cellWidth)
               || cellWidth
        anchors.bottom: parent.bottom
        anchors.top: parent.top

        onCurrentItemChanged: app.currentCredentialCard = currentItem
        visible: entries.count > 0
        ScrollBar.vertical: ScrollBar {
            width: 5
        }
        keyNavigationWraps: true
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
