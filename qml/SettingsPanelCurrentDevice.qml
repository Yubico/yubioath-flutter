import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

StyledExpansionPanel {
    id: currentDevicePanel
    label: getDeviceLabel(yubiKey.currentDevice)
    description: getDeviceDescription(yubiKey.currentDevice)
    keyImage: !!yubiKey.currentDevice ? yubiKey.getCurrentDeviceImage() : "../images/yubikeys-large-transparent"
    isTopPanel: true
    isEnabled: yubiKey.availableDevices.length > 1

    function getDeviceLabel(device) {
        if (!!device) {
            return ("%1").arg(device.name)
        } else {
            return qsTr("Insert your YubiKey")
        }
    }

    function getDeviceDescription(device) {
        if (!!device) {
            return qsTr("Serial number: %1").arg(!!device.serial ? device.serial : "Not available")
        } else {
            return qsTr("No device found")
        }
    }

    ButtonGroup {
        id: deviceButtonGroup
    }

    ColumnLayout {
        Layout.fillWidth: true

        Repeater {
            model: yubiKey.availableDevices
            onModelChanged: {
                if (yubiKey.availableDevices.length < 2) {
                    currentDevicePanel.isExpanded = false
                }
            }
            StyledRadioButton {
                Layout.fillWidth: true
                objectName: index
                checked: !!yubiKey.currentDevice
                         && modelData.serial === yubiKey.currentDevice.serial
                text: getDeviceLabel(modelData)
                description: getDeviceDescription(modelData)
                buttonGroup: deviceButtonGroup
            }
        }

        StyledButton {
            id: selectBtn
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom
            text: "Select"
            enabled: {
                if (!!yubiKey.availableDevices && !!deviceButtonGroup.checkedButton) {
                    var dev = yubiKey.availableDevices[deviceButtonGroup.checkedButton.objectName]
                    return dev !== yubiKey.currentDevice
                } else {
                    return false
                }
            }
            onClicked: {
                yubiKey.refreshDevicesDefault()
                var dev = yubiKey.availableDevices[deviceButtonGroup.checkedButton.objectName]
                yubiKey.selectCurrentSerial(dev.serial,
                                            function (resp) {
                                                if (resp.success) {
                                                    entries.clear()
                                                    yubiKey.currentDevice = dev
                                                    currentDevicePanel.expandAction()
                                                } else {
                                                    console.log("select device failed", resp.error_id)
                                                }
                                            })
            }
        }
    }
}
