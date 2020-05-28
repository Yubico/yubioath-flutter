import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0
import "utils.js" as Utils

StyledExpansionPanel {
    label: "Interfaces"
    description: qsTr("Enable/disable active interfaces on the YubiKey")
    isTopPanel: true
    isEnabled: true

    property var newApplicationsEnabledOverUsb: []
    property var newApplicationsEnabledOverNfc: []



    function configureInterfaces() {
        writeInterfaces()
    }

    function writeInterfaces() {
        yubiKey.writeConfig(newApplicationsEnabledOverUsb,
                            newApplicationsEnabledOverNfc,
                            function (resp) {
                                if (resp.success) {
                                    navigator.snackBar(qsTr("Configured interfaces"))
                                    navigator.home()
                                } else {
                                    navigator.snackBarError(
                                                navigator.getErrorMessage(
                                                    resp.error_id))
                                }
                            })
    }

    function toggleEnabledOverUsb(applicationId, enabled) {
        if (enabled) {
            newApplicationsEnabledOverUsb = Utils.including(
                        newApplicationsEnabledOverUsb, applicationId)
        } else {
            newApplicationsEnabledOverUsb = Utils.without(
                        newApplicationsEnabledOverUsb, applicationId)
        }

    }

    function configurationHasChanged() {
        var enabledYubiKeyUsb = JSON.stringify(
                    yubiKey.currentDevice.usbAppEnabled.sort())
        var enabledUiUsb = JSON.stringify(newApplicationsEnabledOverUsb.sort())
        var enabledYubiKeyNfc = JSON.stringify(
                    yubiKey.currentDevice.nfcAppEnabled.sort())
        var enabledUiNfc = JSON.stringify(newApplicationsEnabledOverNfc.sort())

        return enabledYubiKeyUsb !== enabledUiUsb
                || enabledYubiKeyNfc !== enabledUiNfc
    }

    function validCombination() {
        return newApplicationsEnabledOverUsb.length >= 1
    }

    /*
      Legacy keys below
    */

    function configureModes() {
        yubiKey.setMode(getEnabledInterfaces(), function (resp) {
            if (resp.success) {
                if (!yubiKey.currentDevice.canWriteConfig) {
                    reInsertYubiKey.open()
                } else {
                    navigator.home()
                }
            } else {
                navigator.snackBarError(
                            navigator.getErrorMessage(
                                resp.error_id))
            }
        })
    }

    function getEnabledInterfaces() {
        var interfaces = []
        if (otpModeBtn.checked) {
            interfaces.push('OTP')
        }
        if (fidoModeBtn.checked) {
            interfaces.push('FIDO')
        }
        if (ccidModeBtn.checked) {
            interfaces.push('CCID')
        }
        return interfaces
    }

    function legacyConfigurationHasChanged() {
        var enabledYubiKeyUsbInterfaces = JSON.stringify(
                    yubiKey.currentDevice.usbInterfacesEnabled.sort())
        var enabledUiUsbInterfaces = JSON.stringify(
                    getEnabledInterfaces().sort())
        return enabledYubiKeyUsbInterfaces !== enabledUiUsbInterfaces
    }

    function legacyValidCombination() {
        return otpModeBtn.checked || fidoModeBtn.checked || ccidModeBtn.checked
    }

    RowLayout {
        visible: {
            if (!!yubiKey.currentDevice) {
                yubiKey.supportsNewInterfaces(yubiKey.currentDevice)
            } else {
                false
            }

        }
        ColumnLayout {
            RowLayout {
                Text {
                    id: text
                    text: "Interface"
                    color: "white"
                    Layout.minimumWidth: 200
                }
                Text {
                    id: text2
                    text: "USB"
                    color: "white"
                }
                Text {
                    id: text3
                    text: "NFC"
                    color: "white"
                }
            }

            RowLayout {
                Label {
                    visible: ccidButton1.visible
                    text: "CCID (smart card)"
                    Layout.minimumWidth: 200
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                }

                ButtonGroup {
                        id: ccidBtnGrp
                        exclusive: false
                        checkState: ccidButton1.checkState
                    }

                CheckBox {
                    indicator.width: 16
                    indicator.height: 16

                    id: ccidButton1
                    visible: yubiKey.currentDeviceSupported("OATH") || yubiKey.currentDeviceSupported("PIV") || yubiKey.currentDeviceSupported("OPGP")
                    checkState: ccidBtnGrp.checkState

                }

                CheckBox {
                    indicator.width: 16
                    indicator.height: 16

                    id: ccidButton2
                    visible: false // NFC. False for now

                }

                ToolButton {
                        property bool isExpanded: false
                        id: expandButton
                        onClicked:{
                            isExpanded = !isExpanded
                        }
                        icon.width: 24
                        icon.source: isExpanded ? "../images/up.svg" : "../images/down.svg"
                        icon.color: primaryColor
                        opacity: hovered ? fullEmphasis : lowEmphasis
                        visible: ccidButton1.visible
                        focus: true
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: false
                        }
                    }
            }

            RowLayout {
                visible: expandButton.isExpanded
                Label {
                    id: ccidChild1Text
                    text: "OATH"
                    Layout.minimumWidth: 200
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                }

                CheckBox {
                    indicator.width: 16
                    indicator.height: 16

                    id: ccidChild1
                    ButtonGroup.group: ccidBtnGrp
                    checked: yubiKey.currentDeviceEnabled("OATH")
                    onCheckedChanged: toggleEnabledOverUsb("OATH",
                                                           checked)

                }
            }

            RowLayout {
                visible: expandButton.isExpanded
                Label {
                    id: ccidChild2Text
                    text: "PIV"
                    Layout.minimumWidth: 200
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                }

                CheckBox {
                    indicator.width: 16
                    indicator.height: 16

                    id: ccidChild2
                    ButtonGroup.group: ccidBtnGrp
                    checked: yubiKey.currentDeviceEnabled("PIV")
                    onCheckedChanged: toggleEnabledOverUsb("PIV",
                                                           checked)

                }
            }

            RowLayout {
                visible: expandButton.isExpanded
                Label {
                    id: ccidChild3Text
                    text: "OpenPGP"
                    Layout.minimumWidth: 200
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                }

                CheckBox {
                    indicator.width: 16
                    indicator.height: 16

                    id: ccidChild3
                    ButtonGroup.group: ccidBtnGrp
                    checked: yubiKey.currentDeviceEnabled("OPGP")
                    onCheckedChanged: toggleEnabledOverUsb("OPGP",
                                                           checked)

                }
            }

            RowLayout {
                ButtonGroup {
                        id: fidoBtnGrp
                        exclusive: false
                        checkState: fidoButton1.checkState
                    }

                Label {
                    visible: fidoButton1.visible
                    text: "FIDO (WebAuthn)"
                    Layout.minimumWidth: 200
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                }

                CheckBox {
                    indicator.width: 16
                    indicator.height: 16

                    id: fidoButton1
                    visible: yubiKey.currentDeviceSupported("FIDO2") || yubiKey.currentDeviceSupported("U2F")
                    checkState: fidoBtnGrp.checkState

                }

                CheckBox {
                    indicator.width: 16
                    indicator.height: 16

                    id: fidoButton2
                    visible: false // NFC, false for now

                }

                ToolButton {
                    property bool isExpanded: false
                    id: expandButton2
                    onClicked:{
                        isExpanded = !isExpanded
                    }
                    icon.width: 24
                    icon.source: isExpanded ? "../images/up.svg" : "../images/down.svg"
                    icon.color: primaryColor
                    opacity: hovered ? fullEmphasis : lowEmphasis
                    visible: fidoButton1.visible
                    focus: true
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: false
                    }
                }
            }

            RowLayout {
                visible: expandButton2.isExpanded
                Label {
                    id: fidoChild1Text
                    text: "FIDO2"
                    Layout.minimumWidth: 200
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                }

                CheckBox {
                    indicator.width: 16
                    indicator.height: 16

                    id: fidoChild1
                    ButtonGroup.group: fidoBtnGrp
                    checked: yubiKey.currentDeviceEnabled("FIDO2")
                    onCheckedChanged: toggleEnabledOverUsb("FIDO2",
                                                           checked)
                }
            }

            RowLayout {
                visible: expandButton2.isExpanded
                Label {
                    id: fidoChild2Text
                    text: "FIDO U2F"
                    Layout.minimumWidth: 200
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                }

                CheckBox {
                    indicator.width: 16
                    indicator.height: 16

                    id: fidoChild2
                    ButtonGroup.group: fidoBtnGrp
                    checked: yubiKey.currentDeviceEnabled("U2F")
                    onCheckedChanged: toggleEnabledOverUsb("U2F",
                                                           checked)


                }
            }

            RowLayout {
                visible: yubiKey.currentDeviceSupported("OTP")
                Label {
                    text: "OTP"
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    Layout.minimumWidth: 200
                }

                CheckBox {
                    indicator.width: 16
                    indicator.height: 16

                    id: otpButton1
                    checked: yubiKey.currentDeviceEnabled("OTP")
                    onCheckedChanged: toggleEnabledOverUsb("OTP",
                                                           checked)
                }

                CheckBox {
                    indicator.width: 16
                    indicator.height: 16

                    id: otpButton2
                    visible: false // NFC. False for now

                }
            }

            StyledButton {
                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                text: "Set"
                enabled: configurationHasChanged() && validCombination()
                onClicked: configureInterfaces()
            }



        }

    }

    /*
      Legacy keys below
    */

    RowLayout {
        visible: {
            if (!!yubiKey.currentDevice) {
                !yubiKey.supportsNewInterfaces(yubiKey.currentDevice)
            } else {
                false
            }
        }
        ColumnLayout {
            RowLayout {
                Text {
                    id: text4
                    text: "Interface"
                    color: "white"
                    Layout.minimumWidth: 200
                }
                Text {
                    id: text5
                    text: "USB"
                    color: "white"
                }
                Text {
                    id: text6
                    text: "NFC"
                    color: "white"
                }
            }

            RowLayout {
                visible: yubiKey.currentDevice.usbInterfacesSupported.includes("OTP")
                Label {
                    text: "OTP"
                    Layout.minimumWidth: 200
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                }

                CheckBox {
                    indicator.width: 16
                    indicator.height: 16

                    id: otpModeBtn
                    checked: yubiKey.currentDevice.usbInterfacesEnabled.includes("OTP")

                }
            }

            RowLayout {
                visible: yubiKey.currentDevice.usbInterfacesSupported.includes("FIDO")
                Label {
                    text: "FIDO"
                    Layout.minimumWidth: 200
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                }

                CheckBox {
                    indicator.width: 16
                    indicator.height: 16

                    id: fidoModeBtn
                    checked: yubiKey.currentDevice.usbInterfacesEnabled.includes("FIDO")

                }
            }

            RowLayout {
                visible: yubiKey.currentDevice.usbInterfacesSupported.includes("CCID")
                Label {
                    text: "CCID (smart card)"
                    Layout.minimumWidth: 200
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                }

                CheckBox {
                    indicator.width: 16
                    indicator.height: 16

                    id: ccidModeBtn
                    checked: yubiKey.currentDevice.usbInterfacesEnabled.includes("CCID")

                }

            }

            StyledButton {
                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                text: "Set"
                onClicked: configureModes()
                enabled: legacyConfigurationHasChanged() && legacyValidCombination()
            }
        }

    }

}
