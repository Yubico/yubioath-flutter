import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Pane {
    objectName: 'multipleYubiKeysView'
    property string title: ""

    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Image {
                id: warning
                sourceSize.height: 60
                sourceSize.width: 100
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                fillMode: Image.PreserveAspectFit
                source: "../images/warning.svg"

                ColorOverlay {
                    source: warning
                    color: app.yubicoGrey
                    anchors.fill: warning
                }
            }
            Label {
                text: "Make sure only one YubiKey is inserted"
                font.pixelSize: 12
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            }
        }
    }
}
