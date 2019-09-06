import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2

Dialog {
    margins: 0
    spacing: 0
    modal: true
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2

    width: app.width > 600 ? 600 : app.width * 0.90
    focus: true

    background: Rectangle {
        color: defaultBackground
        radius: 4
    }

    onClosed: {
        navigator.focus = true
    }

    onRejected: {
        close()
        navigator.focus = true
    }

    Component.onCompleted: btnCancel.forceActiveFocus()

    function getDeviceDescription() {
        if (!!yubiKey.currentDevice) {
            return yubiKey.currentDevice.usbInterfacesEnabled.join('+')
        } else if (yubiKey.availableDevices.length > 0
                   && !yubiKey.availableDevices.some(dev => dev.selectable)) {
            return "No compatible device found"
        } else {
            return "No device found"
        }
    }

    ColumnLayout {
        width: parent.width
        Layout.fillWidth: true
        spacing: 0

        ColumnLayout {
            visible: !!yubiKey.currentDevice
            Layout.fillWidth: true
            spacing: 0

            Rectangle {
                id: rectangle
                width: 140
                height: 140
                color: credentialCardCurrentItem
                radius: width * 0.5
                Layout.margins: 16
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    sourceSize.width: 120
                    source: !!yubiKey.currentDevice ? yubiKey.getCurrentDeviceImage() : ""
                    fillMode: Image.PreserveAspectFit
                    visible: parent.visible
                }
            }

            Label {
                text: !!yubiKey.currentDevice ? yubiKey.currentDevice.name : ""
                font.pixelSize: 13
                font.weight: Font.Medium
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                width: parent.width
                wrapMode: Text.WordWrap
                Layout.maximumWidth: parent.width
            }

            Label {
                text: !!yubiKey.currentDevice ? "Serial number: " + yubiKey.currentDevice.serial : ""
                visible: !!yubiKey.currentDevice && yubiKey.currentDevice.serial
                color: formText
                font.pixelSize: 13
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                wrapMode: Text.WordWrap
                Layout.maximumWidth: parent.width
                width: parent.width

            }

            Label {
                text: !!yubiKey.currentDevice ? "Firmware version: " + yubiKey.currentDevice.version : ""
                visible: !!yubiKey.currentDevice && yubiKey.currentDevice.version
                color: formText
                font.pixelSize: 13
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                wrapMode: Text.WordWrap
                Layout.maximumWidth: parent.width
                width: parent.width
            }

            Label {
                text: !!yubiKey.currentDevice ? "Enabled interfaces: " + getDeviceDescription() : ""
                color: formText
                font.pixelSize: 13
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                wrapMode: Text.WordWrap
                Layout.maximumWidth: parent.width
                width: parent.width
            }

            Canvas {
                id: canvas
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.fillWidth: true
                Layout.fillHeight: true
                width: parent.width
                height: 48
                onPaint: {
                    var context = getContext("2d");
                    context.beginPath();
                    context.lineWidth = 1;
                    context.moveTo(0, height / 2);
                    context.strokeStyle = credentialCardCurrentItem
                    context.lineTo(width, height / 2);
                    context.stroke();
                }
            }
        }

        Image {
            source: "../images/yubioath.png"
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.margins: 16
            Layout.topMargin: 0
        }

        Label {
            text: qsTr("Yubico Authenticator ") + appVersion
            font.pixelSize: 13
            font.weight: Font.Medium
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            width: parent.width
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
        }

        Label {
            text: qsTr("Copyright © " + Qt.formatDateTime(
                           new Date(),
                           "yyyy") + ", Yubico AB.")
            color: formText
            font.pixelSize: 13
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
            width: parent.width
        }

        Label {
            text: qsTr("All rights reserved.")
            color: formText
            font.pixelSize: 13
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
            width: parent.width
        }

        DialogButtonBox {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.topMargin: 14
            Layout.rightMargin: -22
            Layout.bottomMargin: -22

            StyledButton {
                id: btnCancel
                text: "Close"
                flat: true
                enabled: true
                font.capitalization: Font.capitalization
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                Keys.onReturnPressed: reject()
                onClicked: reject()
            }
        }
    }
}
