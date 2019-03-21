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
    }
}
