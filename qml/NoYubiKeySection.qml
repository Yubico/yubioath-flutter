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
        Layout.topMargin: -32

        StyledImage {
            id: yubikeys
            iconWidth: 200
            iconHeight: 120
            source: "../images/yubikeys-transparent.png"
            color: formImageOverlay
            bottomPadding: 16
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }

        Label {
            text: {
                if (yubiKey.availableDevices.length > 0 && !yubiKey.availableDevices.some(dev => dev.selectable)) {
                    return "Unsupported device"
                }
                else {
                    return "Insert your YubiKey"
                }
            }
            font.pixelSize: 16
            font.weight: Font.Normal
            lineHeight: 1.5
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            color: formText
        }
        Label {
            text: {
                if (yubiKey.availableDevices.length > 0 && !yubiKey.availableDevices.some(dev => dev.selectable)) {
                    return "Yubico Authenticator requires a CCID/OTP enabled and compatible YubiKey."
                }
                else {
                    return ""
                }
            }
            visible: (yubiKey.availableDevices.length > 0 && !yubiKey.availableDevices.some(dev => dev.selectable))
            Layout.minimumWidth: 320
            Layout.maximumWidth: app.width - dynamicMargin
                                 < dynamicWidth ? app.width - dynamicMargin : dynamicWidth
            horizontalAlignment: Qt.AlignHCenter
            Layout.rowSpan: 1
            lineHeight: 1.1
            wrapMode: Text.WordWrap
            font.pixelSize: 13
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            color: yubicoGrey
        }
    }
}
