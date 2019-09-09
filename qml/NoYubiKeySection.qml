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
            source: "../images/ykfamily.svg"
            color: app.isDark() ? defaultLightForeground : defaultLightOverlay
            iconWidth: 200
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            bottomPadding: 16
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
            color: formLabel
        }

        Label {
            text: settings.useCustomReader ? "Interface: CCID - Custom reader" : "Interface: OTP"
            visible: settings.useCustomReader || settings.otpMode
            Layout.minimumWidth: 320
            Layout.maximumWidth: app.width - dynamicMargin
                                 < dynamicWidth ? app.width - dynamicMargin : dynamicWidth
            horizontalAlignment: Qt.AlignHCenter
            wrapMode: Text.WordWrap
            font.pixelSize: 13
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            color: formLabel
        }
        Label {
            text: {
                var t = yubiKey.availableReaders.filter(reader => reader.toLowerCase().includes(settings.customReaderName.toLowerCase())).toString()
                if (t.length === 0)
                    t = "Custom reader not found. Make sure reader is attached and/or verify settings."
                return t
            }
            visible: settings.useCustomReader
            Layout.minimumWidth: 320
            Layout.maximumWidth: app.width - dynamicMargin
                                 < dynamicWidth ? app.width - dynamicMargin : dynamicWidth
            horizontalAlignment: Qt.AlignHCenter
            wrapMode: Text.WordWrap
            font.pixelSize: 13
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            color: formLabel
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }
}
