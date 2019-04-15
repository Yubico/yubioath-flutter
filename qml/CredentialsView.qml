import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Pane {
    padding: entries.count === 0 ? 50 : 0
    topPadding: entries.count === 0 ? 50 : 16
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

    ColumnLayout {
        visible: entries.count === 0
        spacing: 20

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Image {
                id: people
                sourceSize.width: 80
                Layout.alignment: parent.left | Qt.AlignVCenter
                Layout.topMargin: 10
                Layout.leftMargin: -4
                Layout.bottomMargin: 0
                fillMode: Image.PreserveAspectFit
                source: "../images/people.svg"
                ColorOverlay {
                    source: people
                    color: app.isDark(
                               ) ? app.defaultDarkOverlay : app.defaultLightOverlay
                    anchors.fill: people
                }
            }
            Label {
                text: "No credentials"
                Layout.rowSpan: 1
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                font.bold: true
                lineHeight: 1.5
                Layout.alignment: Qt.AlignHLeft | Qt.AlignVCenter
            }
            Label {
                text: "This YubiKey contains no credentials, how about adding some? For more information how it works please refer to yubico.com/authenticator."
                Layout.minimumWidth: 320
                Layout.maximumWidth: app.width - 100 < 600 ? app.width - 100 : 600
                Layout.rowSpan: 1
                lineHeight: 1.1
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            }
        }
    }

    GridView {
        id: grid

        onCurrentItemChanged: app.currentCredentialCard = currentItem
        visible: entries.count > 0
        ScrollBar.vertical: ScrollBar {
            width: 5
        }
        keyNavigationWraps: true
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
