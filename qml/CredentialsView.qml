import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2

Pane {
    objectName: 'credentialsView'

    property string title: ""

    GridLayout {
        columnSpacing: 8
        rowSpacing: 8
        columns: app.width / 360

        Repeater {
            model: 10
            CredentialCard {
            }
        }

        CredentialCard {
            issuer: ""
            name: "i only have name!"
        }
    }
}
