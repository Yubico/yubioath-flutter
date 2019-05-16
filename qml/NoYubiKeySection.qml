import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ColumnLayout {

    readonly property int dynamicWidth: 600
    readonly property int dynamicMargin: 64

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter

    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        spacing: 16
        Layout.topMargin: -80

        StyledImage {
            id: yubikeys
            iconWidth: 200
            iconHeight: 120
            source: "../images/yubikeys-transparent.png"
            color: formImageOverlay
        }

        Label {
            text: yubiKey.availableDevices.length
                  > 1 ? "Multiple YubiKeys detected" : "Insert your YubiKey"
            font.pixelSize: 13
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            color: formText
        }
    }
}
