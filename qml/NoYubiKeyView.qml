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
            StyledImage {
                id: yubikeys
                iconWidth: 200
                iconHeight: 120
                source: "../images/yubikeys-transparent.png"
                color: app.isDark(
                           ) ? defaultLightForeground : defaultLightOverlay
            }
            Label {
                text: yubiKey.availableDevices.length
                      === 0 ? "Insert your YubiKey" : "Multiple YubiKeys detected"
                font.pixelSize: 13
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            }
        }
    }
}
