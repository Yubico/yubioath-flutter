import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {
    id: panel
    objectName: 'aboutView'
    contentWidth: appWidth
    contentHeight: content.implicitHeight + 32
    anchors.fill: parent

    ScrollBar.vertical: ScrollBar {
        width: 8
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        hoverEnabled: true
        z: 2
    }
    boundsBehavior: Flickable.StopAtBounds

    Keys.onEscapePressed: navigator.home()

    Accessible.ignored: true

    property string title: ""

    property string deviceName: !!yubiKey.currentDevice ? yubiKey.currentDevice.name : ""
    property string deviceSerial: !!yubiKey.currentDevice && !!yubiKey.currentDevice.serial ? yubiKey.currentDevice.serial : ""
    property string deviceVersion: !!yubiKey.currentDevice && !!yubiKey.currentDevice.version ? yubiKey.currentDevice.version : ""
    property string deviceImage: !!yubiKey.currentDevice ? yubiKey.getCurrentDeviceImage() : ""

    ColumnLayout {
        id: content
        anchors.horizontalCenter: parent.horizontalCenter
        width: appWidth * 0.9 > 600 ? 600 : appWidth * 0.9
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
                color: isDark() ? formHighlightItem : yubicoGreen
                radius: width * 0.5
                Layout.bottomMargin: 16
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                StyledImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    iconWidth: 50
                    iconHeight: 50
                    color: primaryColor
                    opacity: highEmphasis
                    source: "../images/logo-mask.svg"
                    visible: isDark()
                }
                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    source: "../images/logo-small.png"
                    sourceSize.width: 56
                    sourceSize.height: 56
                    visible: !isDark()
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
