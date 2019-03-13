import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2

Pane {
    implicitWidth: 300
    Material.elevation: 1
    RowLayout {
        Layout.fillWidth: true
        Rectangle {
            id: icon
            width: 36
            height: 36
            color: Material.accent
            radius: width * 0.5
            Label {
                text: "G"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                color: "white"
            }
        }

        ColumnLayout {
            spacing: 2
            Label {
                text: "Google"
            }
            Label {
                font.pixelSize: 36
                text: qsTr("783 234")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                anchors.centerIn: parent
            }
            Label {
                text: "My account"
            }
        }
        CredentialCardTimer {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
            colorCircle: yubicoGreen
        }
    }
}
