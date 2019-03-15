import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2

Pane {
    implicitWidth: 360
    implicitHeight: 80

    Material.elevation: 0

    property string issuer: "Google"
    property string name: "mr.smith@gmail.com"
    property string code: "159 789"

    background: Rectangle {
            color: "#383838"
        }

    RowLayout {
        spacing: 0
        anchors.fill: parent

        CredentialCardIcon {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            size: 40
            letter: issuer ? issuer.charAt(0) : name.charAt(0)
        }

        ColumnLayout {
            spacing: 0
            Label {
                id: issuerLbl
                text: issuer
                visible: issuer
                font.pointSize: 12
            }
            Label {
                id: codLbl
                font.pixelSize: 24
                color: yubicoGreen
                text: code
            }
            Label {
                id: nameLbl
                text: name
                font.pointSize: 12
            }
        }

        CredentialCardTimer {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            colorCircle: Material.primary
        }
    }
}
