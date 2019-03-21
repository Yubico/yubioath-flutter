import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2

Pane {
    padding: 0
    topPadding: 16
    objectName: 'credentialsView'

    property string title: ""

    GridView {
        id: grid
        ScrollBar.vertical: ScrollBar { width: 5 }
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: true
        anchors.fill: parent
        model: entries
        cellWidth: 372
        cellHeight: 88
        delegate: CredentialCard {
            credential: model.credential
            code: model.code
        }
        flickableChildren: MouseArea {
            anchors.fill: parent
            onClicked: currentIndex = -1
        }
        focus: true
        Component.onCompleted: currentIndex = -1
    }
}
