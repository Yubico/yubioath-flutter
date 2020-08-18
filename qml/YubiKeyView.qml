import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {
    id: panel
    objectName: 'yubiKeyView'
    contentWidth: app.width
    contentHeight: content.visible ? expandedHeight : app.height - toolBar.height
    leftMargin: 0
    rightMargin: 0

    property var expandedHeight: content.implicitHeight + dynamicMargin

    onExpandedHeightChanged: {
        if (expandedHeight > app.height - toolBar.height) {
             scrollBar.active = true
         }
    }

    ScrollBar.vertical: ScrollBar {
        id: scrollBar
        width: 8
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        hoverEnabled: true
        z: 2
    }
    boundsBehavior: Flickable.StopAtBounds

    Accessible.ignored: true

    property string searchFieldPlaceholder: !!yubiKey.currentDevice ? qsTr("Search configuration") : ""

    property string deviceName: !!yubiKey.currentDevice ? yubiKey.currentDevice.name : ""
    property string deviceSerial: !!yubiKey.currentDevice && !!yubiKey.currentDevice.serial ? yubiKey.currentDevice.serial : ""
    property string deviceVersion: !!yubiKey.currentDevice && !!yubiKey.currentDevice.version ? yubiKey.currentDevice.version : ""
    property string deviceImage: !!yubiKey.currentDevice ? yubiKey.getCurrentDeviceImage() : ""

    NoYubiKeySection {
        id: noYubiKeySection
        // Make this section the default view to show when there is errors.
        visible: yubiKey.availableDevices.length === 0
        enabled: visible
        Accessible.ignored: true
    }

    ColumnLayout {
        id: content
        visible: !noYubiKeySection.visible
        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        height: deviceInfo.implicitHeight + deviceConfig.implicitHeight
        width: parent.width
        spacing: 0

        ColumnLayout {
            id: deviceInfo
            visible: !toolBar.searchField.text.length > 0
            spacing: 4
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            width: parent.width
            Layout.leftMargin: 16
            Layout.topMargin: 32
            Layout.rightMargin: 16
            Layout.bottomMargin: 0

            Rectangle {
                width: 120
                height: 120
                color: formHighlightItem
                radius: width * 0.5
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    sourceSize.width: parent.width - 20
                    source: deviceImage
                    fillMode: Image.PreserveAspectFit
                    visible: parent.visible
                }
            }

            Label {
                text: "Device information"
                font.pixelSize: 16
                font.weight: Font.Normal
                lineHeight: 1.8
                Layout.topMargin: 24
                color: yubicoGreen
                opacity: fullEmphasis
            }
            StyledTextField {
                labelText: qsTr("Device type")
                text: deviceName
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
            StyledTextField {
                labelText: qsTr("Serial number")
                text: deviceSerial
                visible: text.length > 0
                enabled: false
                noedit: true
            }

            ToolButton {
                id: control
                onClicked: showDeviceConfiguration = !showDeviceConfiguration
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                icon.width: 24
                icon.source: showDeviceConfiguration  || toolBar.searchField.text.length > 0 ? "../images/arrow-up.svg" : "../images/arrow-down.svg"
                icon.color: primaryColor
                opacity: hovered ? fullEmphasis : lowEmphasis
                focus: true
                text: "Device configuration"
                font.capitalization: Font.MixedCase
                font.weight: Font.Medium
                font.pixelSize: 13
                font.bold: false
                rightPadding: 14
                Layout.topMargin: 16
                Layout.bottomMargin: 0
                height: 32
                Layout.maximumHeight: 32
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: false
                }
            }
        }

        ColumnLayout {
            id: deviceConfig
            visible: showDeviceConfiguration || toolBar.searchField.text.length > 0
            spacing: 0
            width: parent.width
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop

            StyledExpansionContainer {
                title: qsTr("Interfaces")

                SettingsPanelInterfaces {}
            }

            StyledExpansionContainer {
                title: qsTr("Authenticator (OATH)")

                SettingsPanelPasswordMgmt {}
                SettingsPanelResetDevice {}
            }

            StyledExpansionContainer {
                title: qsTr("Security keys (FIDO2)")

                YubiKeyFidoCreatePIN {}
                YubiKeyFidoRegistrations {}
                YubiKeyFidoFingerprints {}
                YubiKeyFidoReset {}
            }

        }
    }
}
