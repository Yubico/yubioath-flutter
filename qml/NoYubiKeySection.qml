import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ColumnLayout {

    readonly property int dynamicWidth: 600
    readonly property int dynamicMargin: 32

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
            text: qsTr("Insert your YubiKey")
            font.pixelSize: 16
            font.weight: Font.Normal
            lineHeight: 1.5
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            color: primaryColor
            opacity: highEmphasis
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
            text: qsTr("Interface: CCID - Custom reader")
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

