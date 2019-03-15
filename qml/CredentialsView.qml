import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2

Pane {
    padding: 0
    topPadding: 8
    objectName: 'credentialsView'

    property string title: ""

    GridLayout {
        columnSpacing: 8
        rowSpacing: 8
        columns: app.width / 360

        Repeater {
            model: 5
            CredentialCard {
            }
        }

        CredentialCard {
            issuer: "TouchyIssuer"
            name: "touch credential"
            code: ""
            touch: true
        }

        CredentialCard {
            issuer: ""
            name: "touch credential"
            code: ""
            touch: true
        }

        CredentialCard {
            issuer: ""
            name: "i only have name!"
        }

        CredentialCard {
            issuer: ""
            name: "eightCharacters"
            code: "91283746"
        }
        CredentialCard {
            issuer: ""
            name: "seveneleven"
            code: "9128741"
        }
    }
}
