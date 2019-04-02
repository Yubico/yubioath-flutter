import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Pane {
    objectName: 'noYubiKeyView'
    topPadding: 0

    property string title: ""

    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        ColumnLayout {
            spacing: 20
            Image {
                id: yubikeys
                sourceSize.height: 0
                Layout.maximumWidth: 200
                Layout.maximumHeight: 120
                fillMode: Image.PreserveAspectFit
                source: "../images/yubikeys-transparent.png"
                ColorOverlay {
                    source: yubikeys
                    color: app.isDark(
                               ) ? app.defaultDarkOverlay : app.defaultLightOverlay
                    anchors.fill: yubikeys
                }
            }
            Label {
                text: "Insert your YubiKey"
                font.pixelSize: 13
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            }
        }
    }
}
