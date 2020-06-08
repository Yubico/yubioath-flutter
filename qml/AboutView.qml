import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {
    id: panel
    objectName: 'aboutView'
    contentWidth: appWidth - 32
    contentHeight: content.implicitHeight + app.height
    anchors.fill: parent
    leftMargin: 16
    rightMargin: 16

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
        width: parent.width
        Layout.fillWidth: true
        spacing: 0

        GridLayout {
            id: deviceInformation
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.topMargin: 24
            Layout.fillWidth: true
            visible: !!yubiKey.currentDevice
            width: parent.width
            columns: 2
            columnSpacing: 16

            ColumnLayout {
                Layout.leftMargin: 12
                Label {
                    text: deviceName
                    font.pixelSize: 14
                    font.weight: Font.Medium
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

        }

        ColumnLayout {
            id: deviceConfiguration
            width: parent.width
            spacing: 0

            StyledExpansionContainer {
                id: sectionAuthenticatorApp
                title: qsTr("Security Codes")

                SettingsPanelPasswordMgmt {}
                SettingsPanelResetDevice {}
            }

        }
    }
}
