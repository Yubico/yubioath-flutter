import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Pane {
    id: panel
    objectName: 'aboutView'

    anchors.fill: parent
    Accessible.ignored: true
    padding: 0
    spacing: 0

    property string title: ""

    property string deviceName: !!yubiKey.currentDevice ? yubiKey.currentDevice.name : ""
    property string deviceSerial: !!yubiKey.currentDevice && !!yubiKey.currentDevice.serial ? yubiKey.currentDevice.serial : ""
    property string deviceVersion: !!yubiKey.currentDevice && !!yubiKey.currentDevice.version ? yubiKey.currentDevice.version : ""
    property string deviceImage: !!yubiKey.currentDevice ? yubiKey.getCurrentDeviceImage() : ""

    ColumnLayout {

        anchors.horizontalCenter: parent.horizontalCenter

        width: app.width * 0.9 > 600 ? 600 : app.width * 0.9
        Layout.fillWidth: true

        GridLayout {
            id: detailsGrid
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.topMargin: 32
            Layout.fillWidth: true
            visible: !!yubiKey.currentDevice
            width: parent.width
            columns: 2
            columnSpacing: 16

            Rectangle {
                width: 80
                height: 80
                color: formHighlightItem
                radius: width * 0.5
                Layout.bottomMargin: 16
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    sourceSize.width: 60
                    source: deviceImage
                    fillMode: Image.PreserveAspectFit
                    visible: parent.visible
                }
            }

            ColumnLayout {
                Label {
                    text: deviceName
                    font.pixelSize: 16
                    font.weight: Font.Normal
                    lineHeight: 1.8
                    color: yubicoGreen
                    opacity: fullEmphasis
                }

                StyledTextField {
                    labelText: qsTr("Serial number")
                    text: deviceSerial
                    visible: text.length > 0
                    enabled: false
                    noedit: true
                }

                StyledTextField {
                    labelText: qsTr("Firmware version")
                    text: deviceVersion
                    visible: text.length > 0
                    enabled: false
                    noedit: true
                }
            }
        }

        GridLayout {
            id: yaVersionInfo
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.topMargin: 32
            Layout.fillWidth: true
            width: parent.width
            columns: 2
            columnSpacing: 16

            Rectangle {
                width: 80
                height: 80
                color: "#9aca3c"
                radius: width * 0.5
                Layout.bottomMargin: 16
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    sourceSize.width: 60
                    source: "../images/yubioath.png"
                    fillMode: Image.PreserveAspectFit
                    visible: parent.visible
                }
            }

            ColumnLayout {
                Label {
                    text: "Yubico Authenticator"
                    font.pixelSize: 16
                    font.weight: Font.Normal
                    lineHeight: 1.8
                    color: yubicoGreen
                    opacity: fullEmphasis
                }

                StyledTextField {
                    labelText: qsTr("Version")
                    text: appVersion
                    enabled: false
                    noedit: true
                }

                Label {
                    text: qsTr("Copyright © " + Qt.formatDateTime(
                                   new Date(),
                                   "yyyy") + ", Yubico AB.")
                    color: primaryColor
                    opacity: lowEmphasis
                    font.pixelSize: 11
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    wrapMode: Text.WordWrap
                    Layout.maximumWidth: parent.width
                    width: parent.width
                }

                Label {
                    text: qsTr("All rights reserved.")
                    color: primaryColor
                    opacity: lowEmphasis
                    font.pixelSize: 11
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    wrapMode: Text.WordWrap
                    Layout.maximumWidth: parent.width
                    width: parent.width
                }
            }
        }
    }
}
