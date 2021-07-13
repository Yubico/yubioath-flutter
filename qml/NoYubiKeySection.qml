import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ColumnLayout {

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter

    height: parent.height

    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

        StyledImage {
            id: yubikeys
            source: "../images/ykfamily.svg"
            color: defaultImageOverlay
            iconWidth: 200
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            bottomPadding: 16
        }

        Label {
            text: yubiKey.availableDevices.length > 0 && !yubiKey.currentDeviceEnabled("OATH")
                  ? qsTr("Unsupported device")
                  : qsTr("Insert your YubiKey")
            font.pixelSize: 16
            font.weight: Font.Normal
            lineHeight: 1.5
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            color: primaryColor
            opacity: highEmphasis
        }
        Label {
            text: qsTr("Authenticator requires a YubiKey with Smart card (CCID) interface enabled.")
            visible: yubiKey.availableDevices.length > 0 && !yubiKey.currentDeviceEnabled("OATH")
            horizontalAlignment: Qt.AlignHCenter
            Layout.minimumWidth: 300
            Layout.maximumWidth: app.width - dynamicMargin
                                 < dynamicWidth ? app.width - dynamicMargin : dynamicWidth
            Layout.rowSpan: 1
            lineHeight: 1.1
            wrapMode: Text.WordWrap
            font.pixelSize: 13
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            color: primaryColor
            opacity: lowEmphasis
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
        Layout.topMargin: 4
        Layout.bottomMargin: 16

        Item {
            height: 1
        }

        Label {
            text: settings.useCustomReader ? qsTr("Interface: CCID - Custom reader") 
                                           : qsTr("Interface: OTP%1").arg(settings.slot1digits < 1 && settings.slot2digits < 1 ? " (no slots configured)"
                                           : "")
            visible: settings.useCustomReader || settings.otpMode
            Layout.minimumWidth: 300
            Layout.maximumWidth: app.width - dynamicMargin
                                 < dynamicWidth ? app.width - dynamicMargin : dynamicWidth
            horizontalAlignment: Qt.AlignHCenter
            wrapMode: Text.WordWrap
            font.pixelSize: 13
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            color: primaryColor
            opacity: lowEmphasis
        }
        Label {
            text: {
                var t = yubiKey.availableReaders.filter(reader => reader.toLowerCase().includes(settings.customReaderName.toLowerCase())).toString()
                if (t.length === 0)
                    t = qsTr("Custom reader not found!")
                return t
            }
            visible: settings.useCustomReader
            Layout.minimumWidth: 300
            Layout.maximumWidth: app.width - dynamicMargin
                                 < dynamicWidth ? app.width - dynamicMargin : dynamicWidth
            horizontalAlignment: Qt.AlignHCenter
            wrapMode: Text.WordWrap
            font.pixelSize: 13
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            color: primaryColor
            opacity: lowEmphasis
            maximumLineCount: 1
            elide: Text.ElideRight
        }
    }

}

