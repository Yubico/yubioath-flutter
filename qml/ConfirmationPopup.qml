import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import QtQuick.Controls.Material 2.2

Dialog {
    padding: 16
    margins: 0
    spacing: 0
    modal: true
    focus: true

    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: app.width * 0.9 > 600 ? 600 : app.width * 0.9

    background: Rectangle {
        color: defaultBackground
        radius: 4
    }

    onClosed: {
        navigator.focus = true
    }

    onAccepted: {
        close()
        acceptedCb()
        navigator.focus = true
    }

    onRejected: {
        close()
        navigator.focus = true
    }

    Component.onCompleted: btnCancel.forceActiveFocus()

    property var issuer
    property var acceptedCb
    property var entry: !!name ? getAddedCredential() : null
    property var currentDevice
    property bool warning: true
    property bool buttons: true
    property bool doNotAskForCopy: false
    property bool showCode: name !== ""
    property bool touch
    property bool isKeyChanged: currentDevice && !!yubiKey.currentDevice && !(yubiKey.currentDevice.hasPassword && !yubiKey.currentDeviceValidated)
                                ? JSON.stringify(yubiKey.currentDevice) !== JSON.stringify(currentDevice)
                                : false
    property string name
    property string heading
    property string message
    property string description
    property string buttonCancel: qsTr("Cancel")
    property string buttonAccept: qsTr("Accept")

    function getAddedCredential() {
        for (var i = 0; i <= entries.count; i++) {
            var entry = entries.get(i)
            if (!!entry && !!entry.credential) {
                if (entry.credential.issuer === issuer
                        && entry.credential.name === name
                        && entry.credential.touch === touch) {
                    return entry
                }
            }
        }
        return null
    }

    function getDeviceLabel(device) {
        if (!!device) {
            return ("%1").arg(device.name)
        } else {
            return qsTr("Insert your YubiKey")
        }
    }

    function getDeviceDescription(device) {
        if (!!device) {
            return qsTr("Serial number: %1").arg(!!device.serial ? device.serial : "Not Available")
        } else if (yubiKey.availableDevices.length > 0
                   && !yubiKey.availableDevices.some(dev => dev.selectable)) {
            return qsTr("No compatible device found")
        } else {
            return qsTr("No device found")
        }
    }

    ColumnLayout {
        width: parent.width

        Label {
            text: heading
            font.pixelSize: 14
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
        }

        Pane {
            padding: 12
            rightPadding: 16
            bottomPadding: 8
            visible: message || showCode
            width: parent.width
            Layout.minimumWidth: parent.width
            Layout.maximumWidth: parent.width
            Layout.topMargin: 16
            background: Rectangle {
                color: warning ? yubicoRed : yubicoGreen
                radius: 4
            }

            RowLayout {
                spacing: 0
                width: parent.width
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                StyledImage {
                    source: warning ? "../images/warning.svg" : "../images/info.svg"
                    color: yubicoWhite
                    iconWidth: 32
                    iconHeight: 32
                    Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    Layout.maximumWidth: 32
                    visible: !entry && !showCode
                }

                Label {
                    text: message
                    color: yubicoWhite
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    lineHeight: 1.2
                    leftPadding: 12
                    wrapMode: Text.WordWrap
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.fillWidth: true
                    visible: !entry && !showCode
                }

                Pane {
                    padding: 0
                    Layout.margins: 0
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    visible: showCode
                    height: 32
                    Layout.alignment: Qt.AlignCenter | Qt.AlignTop
                    background: Rectangle {
                        color: "transparent"
                    }
                    CredentialCard {
                        id: credentialCode
                        isKeyChanged: btnAccept.enabled
                        Layout.margins: 0
                        spacing: 0
                        padding: 0
                        width: parent.width
                        height: parent.height
                        Layout.alignment: Qt.AlignCenter | Qt.AlignTop
                        showFullCredentialCard: false
                        credential: !!entry ? entry.credential : null
                        code: !!entry ? entry.code : null
                    }
                }
            }
        }

        Label {
            Layout.topMargin: 16
            text: description
            color: primaryColor
            opacity: highEmphasis
            font.pixelSize: 13
            lineHeight: 1.2
            visible: description && !entry
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
        }


        StyledExpansionPanel {
            id: currentDevicePanel
            label: qsTr("Create a copy of this account?")
            description: {
                if(isKeyChanged) {
                    return qsTr("Proceed to create copy of account")
                }
                if (isEnabled) {
                    return qsTr("Select YubiKey to use as a copy")
                }
                return qsTr("Insert another YubiKey to create a copy")
            }
            isTopPanel: true
            visible: showCode && !doNotAskForCopy
            Layout.fillWidth: true
            Layout.topMargin: 0
            Layout.bottomMargin: -16
            isEnabled: yubiKey.availableDevices.length > 1
            backgroundColor: "transparent"
            Layout.rightMargin: yubiKey.availableDevices.length > 1 ? -16 : 0
            dropShadow: false
            ButtonGroup {
                id: deviceButtonGroup
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: -16

                Repeater {
                    model: yubiKey.availableDevices
                    StyledRadioButton {
                        Layout.fillWidth: true
                        objectName: index
                        checked: !!yubiKey.currentDevice
                                 && modelData.serial === yubiKey.currentDevice.serial
                        text: getDeviceLabel(modelData)
                        description: getDeviceDescription(modelData)
                        enabled: !!currentDevice && modelData.serial !== currentDevice.serial && modelData.selectable
                        buttonGroup: deviceButtonGroup
                    }
                }

                StyledButton {
                    id: selectBtn
                    Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                    text: qsTr("Select")
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
                                                            yubiKey.calculateAll()
                                                        } else {
                                                            console.log("select device failed", resp.error_id)
                                                        }
                                                    })
                    }
                }
            }
        }


        DialogButtonBox {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.topMargin: 0
            Layout.bottomMargin: -16
            Layout.rightMargin: -8
            padding: 0
            visible: buttons || isKeyChanged

            StyledButton {
                id: btnAccept
                text: qsTr(buttonAccept)
                flat: true
                enabled: currentDevice ? isKeyChanged : true
                critical: warning
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                KeyNavigation.tab: btnCancel
                Keys.onReturnPressed: accept()
                onClicked: accept()
            }

            StyledButton {
                id: btnCancel
                text: qsTr(buttonCancel)
                flat: true
                critical: warning
                enabled: true
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                KeyNavigation.tab: btnAccept
                Keys.onReturnPressed: reject()
                onClicked: reject()
            }
        }
    }
}
