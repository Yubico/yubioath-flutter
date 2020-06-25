import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0
import "utils.js" as Utils

StyledExpansionPanel {
    label: "Interfaces"
    description: qsTr("Enable/disable active interfaces on the YubiKey")

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

    function toggleEnabledOverNfc(applicationId, enabled) {
        if (enabled) {
            newApplicationsEnabledOverNfc = Utils.including(
                        newApplicationsEnabledOverNfc, applicationId)
        } else {
            newApplicationsEnabledOverNfc = Utils.without(
                        newApplicationsEnabledOverNfc, applicationId)
        }
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
            spacing: 0

            RowLayout {
                Text {
                    id: text
                    text: "Interface"
                    color: primaryColor
                    opacity: lowEmphasis
                    font.pixelSize: 12
                    Layout.minimumWidth: 100
                }
                RowLayout {
                    spacing: 0
                    Layout.maximumWidth: 40
                    Layout.minimumWidth: 40
                    StyledImage {
                        source: "../images/usb.svg"
                        color: primaryColor
                        opacity: lowEmphasis
                        padding: 0
                        iconWidth: 16
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    }
                    Text {
                        id: text2
                        text: "USB"
                        Layout.leftMargin: -16
                        color: primaryColor
                        opacity: lowEmphasis
                        font.pixelSize: 12
                    }
                }
                Item {
                    width: 8
                }
                RowLayout {
                    visible: ccidButton2.visible || fidoButton2.visible || otpButton2.visible
                    spacing: 0
                    Layout.maximumWidth: 40
                    Layout.minimumWidth: 40
                    StyledImage {
                        source: "../images/nfc.svg"
                        color: primaryColor
                        opacity: lowEmphasis
                        padding: 0
                        iconWidth: 16
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    }
                    Text {
                        id: text3
                        text: "NFC"
                        Layout.leftMargin: -16
                        color: primaryColor
                        opacity: lowEmphasis
                        font.pixelSize: 12
                    }
                }
            }

            RowLayout {
                Label {
                    visible: ccidButton1.visible
                    text: "CCID (smart card)"
                    Layout.minimumWidth: 130
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                }

                ButtonGroup {
                        id: ccidBtnGrpUsb
                        exclusive: false
                        checkState: ccidButton1.checkState
                    }

                ButtonGroup {
                        id: ccidBtnGrpNfc
                        exclusive: false
                        checkState: ccidButton2.checkState
                    }

                CheckBox {
                    id: ccidButton1
                    visible: !!yubiKey.currentDevice ? (yubiKey.currentDevice.usbAppSupported.includes("OATH") || yubiKey.currentDevice.usbAppSupported.includes("PIV") || yubiKey.currentDevice.usbAppSupported.includes("OPGP")) : ""
                    checkState: ccidBtnGrpUsb.checkState

                }

                CheckBox {
                    id: ccidButton2
                    visible: !!yubiKey.currentDevice ? (yubiKey.currentDevice.nfcAppSupported.includes("OATH") || yubiKey.currentDevice.nfcAppSupported.includes("PIV") || yubiKey.currentDevice.nfcAppSupported.includes("OPGP")) : ""
                    checkState: ccidBtnGrpNfc.checkState
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
                        visible: ccidButton1.visible || ccidButton2.visible
                        focus: true
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: false
                        }
                    }
            }

            RowLayout {
                Label {
                    id: ccidChild1Text
                    text: "OATH"
                    Layout.leftMargin: 16
                    Layout.minimumWidth: 114
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                    visible: expandButton.isExpanded

                }

                CheckBox {
                    id: ccidChild1
                    ButtonGroup.group: ccidBtnGrpUsb
                    checked: !!yubiKey.currentDevice ? yubiKey.currentDevice.usbAppEnabled.includes("OATH") : ""
                    onCheckedChanged: toggleEnabledOverUsb("OATH",
                                                           checked)

                    visible: !!yubiKey.currentDevice ? (yubiKey.currentDevice.usbAppSupported.includes("OATH") && expandButton.isExpanded) : ""

                }

                CheckBox {
                    id: ccidChild11
                    ButtonGroup.group: ccidBtnGrpNfc
                    visible: !!yubiKey.currentDevice ? (yubiKey.currentDevice.nfcAppSupported.includes("OATH") && expandButton.isExpanded) : ""
                    checked: !!yubiKey.currentDevice ? yubiKey.currentDevice.nfcAppEnabled.includes("OATH") : ""
                    onCheckedChanged: toggleEnabledOverNfc("OATH",
                                                           checked)
                }
            }

            RowLayout {
                Label {
                    id: ccidChild2Text
                    text: "PIV"
                    Layout.leftMargin: 16
                    Layout.minimumWidth: 114
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                    visible: expandButton.isExpanded
                }

                CheckBox {
                    id: ccidChild2
                    ButtonGroup.group: ccidBtnGrpUsb
                    checked: !!yubiKey.currentDevice ? yubiKey.currentDevice.usbAppEnabled.includes("PIV") : ""
                    onCheckedChanged: toggleEnabledOverUsb("PIV",
                                                           checked)

                    visible: !!yubiKey.currentDevice ? (yubiKey.currentDevice.usbAppSupported.includes("PIV") && expandButton.isExpanded) : ""

                }

                CheckBox {
                    id: ccidChild21
                    ButtonGroup.group: ccidBtnGrpNfc
                    visible: !!yubiKey.currentDevice ? (yubiKey.currentDevice.nfcAppSupported.includes("PIV") && expandButton.isExpanded) : ""
                    checked: !!yubiKey.currentDevice ? yubiKey.currentDevice.nfcAppEnabled.includes("PIV") : ""
                    onCheckedChanged: toggleEnabledOverNfc("PIV",
                                                           checked)
                }
            }

            RowLayout {
                Label {
                    id: ccidChild3Text
                    text: "OpenPGP"
                    Layout.leftMargin: 16
                    Layout.minimumWidth: 114
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                    visible: expandButton.isExpanded
                }

                CheckBox {
                    id: ccidChild3
                    ButtonGroup.group: ccidBtnGrpUsb
                    checked: !!yubiKey.currentDevice ? yubiKey.currentDevice.usbAppEnabled.includes("OPGP") : ""
                    onCheckedChanged: toggleEnabledOverUsb("OPGP",
                                                           checked)

                    visible: !!yubiKey.currentDevice ? (yubiKey.currentDevice.usbAppSupported.includes("OPGP") && expandButton.isExpanded) : ""

                }

                CheckBox {
                    id: ccidChild31
                    ButtonGroup.group: ccidBtnGrpNfc
                    visible: !!yubiKey.currentDevice ? (yubiKey.currentDevice.nfcAppSupported.includes("OPGP") && expandButton.isExpanded) : ""
                    checked: !!yubiKey.currentDevice ? yubiKey.currentDevice.nfcAppEnabled.includes("OPGP") : ""
                    onCheckedChanged: toggleEnabledOverNfc("OPGP",
                                                           checked)
                }


            }

            Label {
                text: "The CCID interfaces includes smart card, encryption and security codes functionality."
                color: primaryColor
                opacity: disabledEmphasis
                font.pixelSize: 12
                maximumLineCount: 2
                Layout.maximumWidth: parent.width
                wrapMode: Text.WordWrap
            }

            RowLayout {
                ButtonGroup {
                        id: fidoBtnGrpUsb
                        exclusive: false
                        checkState: fidoButton1.checkState
                    }

                ButtonGroup {
                        id: fidoBtnGrpNfc
                        exclusive: false
                        checkState: fidoButton2.checkState
                    }

                Label {
                    visible: fidoButton1.visible || fidoButton2.visible
                    text: "FIDO (WebAuthn)"
                    Layout.minimumWidth: 130
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                }

                CheckBox {
                    id: fidoButton1
                    visible: !!yubiKey.currentDevice ? (yubiKey.currentDevice.usbAppSupported.includes("FIDO2") || yubiKey.currentDevice.usbAppSupported.includes("U2F")) : ""
                    checkState: fidoBtnGrpUsb.checkState

                }

                CheckBox {
                    id: fidoButton2
                    visible: !!yubiKey.currentDevice ? (yubiKey.currentDevice.nfcAppSupported.includes("FIDO2") || yubiKey.currentDevice.nfcAppSupported.includes("U2F")) : ""
                    checkState: fidoBtnGrpNfc.checkState

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
                    visible: fidoButton1.visible || fidoButton2.visible
                    focus: true
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: false
                    }
                }
            }

            RowLayout {
                Label {
                    id: fidoChild1Text
                    text: "FIDO2"
                    Layout.leftMargin: 16
                    Layout.minimumWidth: 114
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                    visible: expandButton2.isExpanded
                }

                CheckBox {
                    id: fidoChild1
                    ButtonGroup.group: fidoBtnGrpUsb
                    checked: !!yubiKey.currentDevice ? yubiKey.currentDevice.usbAppEnabled.includes("FIDO2") : ""
                    onCheckedChanged: toggleEnabledOverUsb("FIDO2",
                                                           checked)
                    visible: !!yubiKey.currentDevice ? (yubiKey.currentDevice.usbAppSupported.includes("FIDO2") && expandButton2.isExpanded) : ""
                }

                CheckBox {
                    id: fidoChild11
                    ButtonGroup.group: fidoBtnGrpNfc
                    visible: !!yubiKey.currentDevice ? (yubiKey.currentDevice.nfcAppSupported.includes("FIDO2") && expandButton2.isExpanded) : ""
                    checked: !!yubiKey.currentDevice ? yubiKey.currentDevice.nfcAppEnabled.includes("FIDO2") : ""
                    onCheckedChanged: toggleEnabledOverNfc("FIDO2",
                                                           checked)
                }
            }

            RowLayout {

                Label {
                    id: fidoChild2Text
                    text: "FIDO U2F"
                    Layout.leftMargin: 16
                    Layout.minimumWidth: 114
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    visible: expandButton2.isExpanded
                }

                CheckBox {
                    id: fidoChild2
                    ButtonGroup.group: fidoBtnGrpUsb
                    checked: !!yubiKey.currentDevice ? yubiKey.currentDevice.usbAppEnabled.includes("U2F") : ""
                    onCheckedChanged: toggleEnabledOverUsb("U2F",
                                                           checked)
                    visible: !!yubiKey.currentDevice ? (yubiKey.currentDevice.usbAppSupported.includes("U2F") && expandButton2.isExpanded) : ""
                }

                CheckBox {
                    id: fidoChild21
                    ButtonGroup.group: fidoBtnGrpNfc
                    visible: !!yubiKey.currentDevice ? (yubiKey.currentDevice.nfcAppSupported.includes("U2F") && expandButton2.isExpanded) : ""
                    checked: !!yubiKey.currentDevice ? yubiKey.currentDevice.nfcAppEnabled.includes("U2F") : ""
                    onCheckedChanged: toggleEnabledOverNfc("U2F",
                                                           checked)
                }


            }

            Label {
                text: "The FIDO protocols is used in the W3C WebAuthn standard adopte by all web browsers."
                color: primaryColor
                opacity: disabledEmphasis
                font.pixelSize: 12
                maximumLineCount: 2
                Layout.maximumWidth: parent.width
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Label {
                    text: "OTP"
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    Layout.minimumWidth: 130
                    visible: !!yubiKey.currentDevice ? yubiKey.currentDevice.usbAppSupported.includes("OTP") : ""
                }

                CheckBox {
                    id: otpButton1
                    checked: !!yubiKey.currentDevice ? yubiKey.currentDevice.usbAppEnabled.includes("OTP") : ""
                    onCheckedChanged: toggleEnabledOverUsb("OTP",
                                                           checked)
                    visible: !!yubiKey.currentDevice ? yubiKey.currentDevice.usbAppSupported.includes("OTP") : ""
                }

                CheckBox {
                    id: otpButton2
                    visible: !!yubiKey.currentDevice ? yubiKey.currentDevice.nfcAppSupported.includes("OTP") : ""
                    checked: !!yubiKey.currentDevice ? yubiKey.currentDevice.nfcAppEnabled.includes("OTP") : ""
                    onCheckedChanged: toggleEnabledOverNfc("OTP",
                                                           checked)
                }
            }

            Label {
                text: "Protocols for one-time passwords, challenge response, static passwords etc."
                color: primaryColor
                opacity: disabledEmphasis
                font.pixelSize: 12
                maximumLineCount: 2
                Layout.maximumWidth: parent.width
                wrapMode: Text.WordWrap
            }

            StyledButton {
                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                Layout.topMargin: 16
                text: "Set"
                enabled: !!yubiKey.currentDevice && configurationHasChanged() && validCombination()
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
                    Layout.minimumWidth: 130
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
                visible: !!yubiKey.currentDevice ? yubiKey.currentDevice.usbInterfacesSupported.includes("OTP") : ""
                Label {
                    text: "OTP"
                    Layout.minimumWidth: 130
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                }

                CheckBox {
                    id: otpModeBtn
                    checked: !!yubiKey.currentDevice ? yubiKey.currentDevice.usbInterfacesEnabled.includes("OTP") : ""

                }
            }

            RowLayout {
                visible: !!yubiKey.currentDevice ? yubiKey.currentDevice.usbInterfacesSupported.includes("FIDO") : ""
                Label {
                    text: "FIDO"
                    Layout.minimumWidth: 130
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                }

                CheckBox {
                    id: fidoModeBtn
                    checked: !!yubiKey.currentDevice ? yubiKey.currentDevice.usbInterfacesEnabled.includes("FIDO") : ""

                }
            }

            RowLayout {
                visible: !!yubiKey.currentDevice ? yubiKey.currentDevice.usbInterfacesSupported.includes("CCID") : ""
                Label {
                    text: "CCID (smart card)"
                    Layout.minimumWidth: 130
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                }

                CheckBox {
                    id: ccidModeBtn
                    checked: !!yubiKey.currentDevice ? yubiKey.currentDevice.usbInterfacesEnabled.includes("CCID") : ""

                }

            }

            StyledButton {
                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                text: "Set"
                onClicked: configureModes()
                enabled: !!yubiKey.currentDevice && legacyConfigurationHasChanged() && legacyValidCombination()
            }
        }

    }

}
