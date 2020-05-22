import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ColumnLayout {

    property string deviceName: !!yubiKey.currentDevice ? yubiKey.currentDevice.name : ""
    property string deviceSerial: !!yubiKey.currentDevice && !!yubiKey.currentDevice.serial ? yubiKey.currentDevice.serial : ""
    property string deviceVersion: !!yubiKey.currentDevice && !!yubiKey.currentDevice.version ? yubiKey.currentDevice.version : ""
    property string deviceImage: !!yubiKey.currentDevice ? yubiKey.getCurrentDeviceImage() : ""

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter

    width: app.width * 0.9 > 600 ? 600 : app.width * 0.9
    height: parent.height
    Layout.fillWidth: true

    states: [
                State {
                    when: app.height < 420
                    PropertyChanges { target: detailsGrid; columns: 2 }
                    PropertyChanges { target: addBtn; text: qsTr("Add") }
                }
            ]

    GridLayout {
        id: detailsGrid
        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
        Layout.topMargin: 32
        Layout.fillWidth: true
        width: parent.width
        columns: 1
        columnSpacing: 16

        Rectangle {
            width: 100
            height: 100
            color: formHighlightItem
            radius: width * 0.5
            Layout.bottomMargin: 16
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                sourceSize.width: 80
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

            RowLayout {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                spacing: 8
                Layout.topMargin: 16
                StyledButton {
                    text: qsTr("Settings")
                    focus: true
                    onClicked: navigator.goToSettings()
                    Keys.onReturnPressed: navigator.goToSettings()
                    Keys.onEnterPressed: navigator.goToSettings()
                }
                StyledButton {
                    id: addBtn
                    text: qsTr("Add account")
                    enabled: yubiKey.currentDeviceOathEnabled()
                    primary: true
                    focus: true
                    onClicked: navigator.goToNewCredential()
                    Keys.onReturnPressed: navigator.goToNewCredential()
                    Keys.onEnterPressed: navigator.goToNewCredential()
                }
            }
        }
    }
}
