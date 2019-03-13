import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2

Pane {
    implicitWidth: 320
    implicitHeight: 100

    Material.elevation: 1

    property string issuer: "Google"
    property string name: "mr.smith@gmail.com"
    property string code: "159 789"

    RowLayout {
        anchors.fill: parent

        CredentialCardIcon {
            size: 60
            letter: issuer ? issuer.charAt(0) : name.charAt(0)
        }

        ColumnLayout {
            spacing: 0
            Label {
                id: issuerLbl
                text: issuer
                visible: issuer
                font.pointSize: 10
            }
            Label {
                id: codLbl
                font.pixelSize: 37
                text: code
            }
            Label {
                id: nameLbl
                text: name
                font.pointSize: 10
            }
        }

        CredentialCardTimer {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            colorCircle: Material.primary
        }
    }
}
