import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2

Pane {
    padding: 0
    topPadding: 0
    objectName: 'credentialsView'

    property string title: ""

    EntriesModel {
        id: filteredEntries
    }

    function filteredCredentials() {
        filteredEntries.clear()
        if (entries !== null && toolBar.searchField.text.length > 0) {
            for (var i = 0; i < entries.count; i++) {
                var entry = entries.get(i)
                if (entry.credential.key.toLowerCase().indexOf(
                            toolBar.searchField.text.toLowerCase()) !== -1) {
                    filteredEntries.append(entry)
                }
            }
            return true
        }
        return false
    }

    GridView {
        id: grid
        ScrollBar.vertical: ScrollBar {
            width: 5
        }
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: true
        anchors.fill: parent
        model: filteredCredentials() ? filteredEntries : entries
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
                currentItem.calculateCard()
            }
        }
        Keys.onDeletePressed: {
            if (currentIndex !== -1) {
                currentItem.deleteCard(currentIndex)
            }
        }
    }
}
