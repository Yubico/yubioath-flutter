import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0
import "utils.js" as Utils

Flickable {

    id: settingsPanel
    objectName: 'yubiKeyInterfacesFlickable'
    contentWidth: app.width
    contentHeight: content.height + dynamicMargin

    onContentHeightChanged: {
        if (contentHeight > app.height - toolBar.height) {
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

    property string searchFieldPlaceholder: ""

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
                                    if (settings.useCustomReader) {
                                        yubiKey.loadDevicesCustomReaderOuter()
                                    } else {
                                        yubiKey.loadDevicesUsbOuter()
                                    }
                                } else {
                                    navigator.snackBarError(
                                                navigator.getErrorMessage(
                                                    resp.error_id))
                                }
                            })
    }

    function toggleEnabledOverNfc(applicationId, enabled) {
        if (enabled) {
            newApplicationsEnabledOverNfc = Utils.including(newApplicationsEnabledOverNfc, applicationId)
        } else {
            newApplicationsEnabledOverNfc = Utils.without(newApplicationsEnabledOverNfc, applicationId)
        }
    }

    function toggleEnabledOverUsb(applicationId, enabled) {
        if (enabled) {
            newApplicationsEnabledOverUsb = Utils.including(newApplicationsEnabledOverUsb, applicationId)
        } else {
            newApplicationsEnabledOverUsb = Utils.without(newApplicationsEnabledOverUsb, applicationId)
        }
    }

    function configurationHasChanged() {
        var enabledYubiKeyUsb = JSON.stringify(yubiKey.currentDevice.usbAppEnabled.sort())
        var enabledUiUsb = JSON.stringify(newApplicationsEnabledOverUsb.sort())
        var enabledYubiKeyNfc = JSON.stringify(yubiKey.currentDevice.nfcAppEnabled.sort())
        var enabledUiNfc = JSON.stringify(newApplicationsEnabledOverNfc.sort())
        return enabledYubiKeyUsb !== enabledUiUsb || enabledYubiKeyNfc !== enabledUiNfc
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
                    navigator.confirm({
                                "message": qsTr("Remove and re-insert your YubiKey!"),
                                "buttons": false,
                                "warning": false,
                                "closePolicy": Popup.NoAutoClose
                                })
                }
            } else {
                navigator.snackBarError(
                    navigator.getErrorMessage(resp.error_id))
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
        var enabledYubiKeyUsbInterfaces = JSON.stringify(yubiKey.currentDevice.usbInterfacesEnabled.sort())
        var enabledUiUsbInterfaces = JSON.stringify(getEnabledInterfaces().sort())
        return enabledYubiKeyUsbInterfaces !== enabledUiUsbInterfaces
    }

    function legacyValidCombination() {
        return otpModeBtn.checked || fidoModeBtn.checked || ccidModeBtn.checked
    }

    ColumnLayout {
        width: settingsPanel.contentWidth
        id: content
        spacing: 0

        ColumnLayout {
            Layout.leftMargin: 16
            Layout.rightMargin: 16

            Label {
                id: containerLabel
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                text: "Interfaces"
                color: Material.primary
                font.pixelSize: 16
                font.weight: Font.Normal
                topPadding: 24
                bottomPadding: 8
                Layout.fillWidth: true
            }
 
 
        Layout.fillWidth: true
        Layout.maximumWidth: app.width

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

        GridLayout {
            id: gridLayout
            columns: nfcColumnLabel.visible ? 4 : 3
            rowSpacing: 0
            columnSpacing: 0
            Layout.leftMargin: 0
            Layout.rightMargin: -12
            Layout.fillWidth: true
            visible: !!yubiKey.currentDevice && yubiKey.supportsNewInterfaces(yubiKey.currentDevice)

            // header

            Text {
                text: ""
                color: primaryColor
                opacity: lowEmphasis
                font.pixelSize: 12
                Layout.fillWidth: true
            }
            RowLayout {
                spacing: 0
                Layout.margins: 0

                StyledImage {
                    source: "../images/usb.svg"
                    color: primaryColor
                    opacity: lowEmphasis
                    Layout.leftMargin: -24
                    leftInset: 0
                    Layout.margins: 0
                    padding: 0
                    iconWidth: 16
                }
                Text {
                    text: "USB"
                    Layout.leftMargin: -20
                    color: primaryColor
                    opacity: lowEmphasis
                    font.pixelSize: 12
                }
            }
            RowLayout {
                id: nfcColumnLabel
                visible: ccidButton2.visible || fidoButton2.visible || otpButton2.visible
                Layout.margins: 0
                spacing: 0
                Item {
                    width: 8
                }
                StyledImage {
                    source: "../images/nfc.svg"
                    color: primaryColor
                    opacity: lowEmphasis
                    leftInset: 0
                    Layout.margins: 0
                    Layout.leftMargin: -24
                    padding: 0
                    iconWidth: 16
                }
                Text {
                    text: "NFC"
                    Layout.leftMargin: -20
                    color: primaryColor
                    opacity: lowEmphasis
                    font.pixelSize: 12
                }
            }

            Item {
                width: 44
            }

            // CCID grouping

            Label {
                visible: ccidButton1.visible || ccidButton2.visible
                text: "Smart card (CCID)"
            }

            CheckBox {
                id: ccidButton1
                visible: !!yubiKey.currentDevice && (yubiKey.currentDevice.usbAppSupported.includes("OATH")
                                                    || yubiKey.currentDevice.usbAppSupported.includes("PIV")
                                                    || yubiKey.currentDevice.usbAppSupported.includes("OPENPGP"))
                checkState: ccidBtnGrpUsb.checkState
            }

            CheckBox {
                id: ccidButton2
                visible: !!yubiKey.currentDevice && (yubiKey.currentDevice.nfcAppSupported.includes("OATH")
                                                    || yubiKey.currentDevice.nfcAppSupported.includes("PIV")
                                                    || yubiKey.currentDevice.nfcAppSupported.includes("OPENPGP"))
                checkState: ccidBtnGrpNfc.checkState
            }

            ToolButton {
                property bool isExpanded: false
                id: expandButton
                onClicked: isExpanded = !isExpanded
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

            // CCID OATH

            Label {
                id: ccidChild1Text
                text: "OATH"
                Layout.leftMargin: 16
                visible: expandButton.isExpanded
            }

            CheckBox {
                id: ccidChild1
                ButtonGroup.group: ccidBtnGrpUsb
                checked: !!yubiKey.currentDevice && yubiKey.currentDevice.usbAppEnabled.includes("OATH")
                visible: !!yubiKey.currentDevice && (yubiKey.currentDevice.usbAppSupported.includes("OATH") && expandButton.isExpanded)
                onCheckedChanged: toggleEnabledOverUsb("OATH", checked)
            }

            CheckBox {
                id: ccidChild11
                ButtonGroup.group: ccidBtnGrpNfc
                checked: !!yubiKey.currentDevice && yubiKey.currentDevice.nfcAppEnabled.includes("OATH")
                visible: !!yubiKey.currentDevice && (yubiKey.currentDevice.nfcAppSupported.includes("OATH") && expandButton.isExpanded)
                onCheckedChanged: toggleEnabledOverNfc("OATH", checked)
            }

            Item {
                visible: expandButton.isExpanded
                width: 44
            }

            // CCID PIV

            Label {
                id: ccidChild2Text
                text: "PIV"
                Layout.leftMargin: 16
                visible: expandButton.isExpanded
            }

            CheckBox {
                id: ccidChild2
                ButtonGroup.group: ccidBtnGrpUsb
                checked: !!yubiKey.currentDevice && yubiKey.currentDevice.usbAppEnabled.includes("PIV")
                visible: !!yubiKey.currentDevice && (yubiKey.currentDevice.usbAppSupported.includes("PIV") && expandButton.isExpanded)
                onCheckedChanged: toggleEnabledOverUsb("PIV", checked)
            }

            CheckBox {
                id: ccidChild21
                ButtonGroup.group: ccidBtnGrpNfc
                checked: !!yubiKey.currentDevice && yubiKey.currentDevice.nfcAppEnabled.includes("PIV")
                visible: !!yubiKey.currentDevice && (yubiKey.currentDevice.nfcAppSupported.includes("PIV") && expandButton.isExpanded)
                onCheckedChanged: toggleEnabledOverNfc("PIV", checked)
            }

            Item {
                visible: expandButton.isExpanded
                width: 44
            }

            // CCID OpenPGP

            Label {
                id: ccidChild3Text
                text: "OpenPGP"
                Layout.leftMargin: 16
                visible: expandButton.isExpanded
            }

            CheckBox {
                id: ccidChild3
                ButtonGroup.group: ccidBtnGrpUsb
                checked: !!yubiKey.currentDevice && yubiKey.currentDevice.usbAppEnabled.includes("OPENPGP")
                visible: !!yubiKey.currentDevice && (yubiKey.currentDevice.usbAppSupported.includes("OPENPGP") && expandButton.isExpanded)
                onCheckedChanged: toggleEnabledOverUsb("OPENPGP", checked)
            }

            CheckBox {
                id: ccidChild31
                ButtonGroup.group: ccidBtnGrpNfc
                checked: !!yubiKey.currentDevice && yubiKey.currentDevice.nfcAppEnabled.includes("OPENPGP")
                visible: !!yubiKey.currentDevice && (yubiKey.currentDevice.nfcAppSupported.includes("OPENPGP") && expandButton.isExpanded)
                onCheckedChanged: toggleEnabledOverNfc("OPENPGP", checked)
            }

            Item {
                visible: expandButton.isExpanded
                width: 44
            }

            // CCID description

            Label {
                text: "The CCID interfaces include smart card, encryption and security codes functionality."
                visible: ccidButton1.visible || ccidButton2.visible
                color: primaryColor
                opacity: disabledEmphasis
                font.pixelSize: 12
                maximumLineCount: 2
                Layout.maximumWidth: app.width - 48
                Layout.columnSpan: gridLayout.columns
                wrapMode: Text.WordWrap
                Layout.bottomMargin: 16
            }

            // FIDO grouping

            Label {
                visible: fidoButton1.visible || fidoButton2.visible
                text: "WebAuthn (FIDO)"
            }

            CheckBox {
                id: fidoButton1
                visible: !!yubiKey.currentDevice && (yubiKey.currentDevice.usbAppSupported.includes("FIDO2")
                                                    || yubiKey.currentDevice.usbAppSupported.includes("U2F"))
                checkState: fidoBtnGrpUsb.checkState
            }

            CheckBox {
                id: fidoButton2
                visible: !!yubiKey.currentDevice && (yubiKey.currentDevice.nfcAppSupported.includes("FIDO2")
                                                    || yubiKey.currentDevice.nfcAppSupported.includes("U2F"))
                checkState: fidoBtnGrpNfc.checkState
            }

            ToolButton {
                property bool isExpanded: false
                id: expandButton2
                onClicked: isExpanded = !isExpanded
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

            // FIDO2

            Label {
                id: fidoChild1Text
                text: "FIDO2"
                Layout.leftMargin: 16
                visible: expandButton2.isExpanded
            }

            CheckBox {
                id: fidoChild1
                ButtonGroup.group: fidoBtnGrpUsb
                checked: !!yubiKey.currentDevice && yubiKey.currentDevice.usbAppEnabled.includes("FIDO2")
                visible: !!yubiKey.currentDevice && (yubiKey.currentDevice.usbAppSupported.includes("FIDO2") && expandButton2.isExpanded)
                onCheckedChanged: toggleEnabledOverUsb("FIDO2", checked)
            }

            CheckBox {
                id: fidoChild11
                ButtonGroup.group: fidoBtnGrpNfc
                visible: !!yubiKey.currentDevice && (yubiKey.currentDevice.nfcAppSupported.includes("FIDO2") && expandButton2.isExpanded)
                checked: !!yubiKey.currentDevice && yubiKey.currentDevice.nfcAppEnabled.includes("FIDO2")
                onCheckedChanged: toggleEnabledOverNfc("FIDO2", checked)
            }

            Item {
                visible: expandButton2.isExpanded
                width: 44
            }

            // FIDO U2F

            Label {
                id: fidoChild2Text
                text: "FIDO U2F"
                Layout.leftMargin: 16
                visible: expandButton2.isExpanded
            }

            CheckBox {
                id: fidoChild2
                ButtonGroup.group: fidoBtnGrpUsb
                checked: !!yubiKey.currentDevice && yubiKey.currentDevice.usbAppEnabled.includes("U2F")
                visible: !!yubiKey.currentDevice && (yubiKey.currentDevice.usbAppSupported.includes("U2F") && expandButton2.isExpanded)
                onCheckedChanged: toggleEnabledOverUsb("U2F", checked)
            }

            CheckBox {
                id: fidoChild21
                ButtonGroup.group: fidoBtnGrpNfc
                visible: !!yubiKey.currentDevice && (yubiKey.currentDevice.nfcAppSupported.includes("U2F") && expandButton2.isExpanded)
                checked: !!yubiKey.currentDevice && yubiKey.currentDevice.nfcAppEnabled.includes("U2F")
                onCheckedChanged: toggleEnabledOverNfc("U2F", checked)
            }

            // FIDO description

            Label {
                text: "The FIDO protocols are used in the W3C WebAuthn standard adopted by all web browsers."
                visible: fidoButton1.visible || fidoButton2.visible
                color: primaryColor
                opacity: disabledEmphasis
                font.pixelSize: 12
                maximumLineCount: 2
                Layout.maximumWidth: app.width - 48
                Layout.columnSpan: gridLayout.columns
                wrapMode: Text.WordWrap
                Layout.bottomMargin: 16

            }

            // OTP

            Label {
                text: "OTP"
                visible: !!yubiKey.currentDevice && yubiKey.currentDevice.usbAppSupported.includes("OTP")
            }

            CheckBox {
                id: otpButton1
                checked: !!yubiKey.currentDevice && yubiKey.currentDevice.usbAppEnabled.includes("OTP")
                visible: !!yubiKey.currentDevice && yubiKey.currentDevice.usbAppSupported.includes("OTP")
                onCheckedChanged: toggleEnabledOverUsb("OTP", checked)
            }

            CheckBox {
                id: otpButton2
                checked: !!yubiKey.currentDevice && yubiKey.currentDevice.nfcAppEnabled.includes("OTP")
                visible: !!yubiKey.currentDevice && yubiKey.currentDevice.nfcAppSupported.includes("OTP")
                onCheckedChanged: toggleEnabledOverNfc("OTP", checked)
            }

            Item {
                visible: otpButton1.visible || otpButton2.visible
                width: 44
            }

            // OTP description

            Label {
                text: "Protocols for one-time passwords, challenge response, static passwords etc."
                visible: otpButton1.visible || otpButton2.visible
                color: primaryColor
                opacity: disabledEmphasis
                font.pixelSize: 12
                maximumLineCount: 2
                Layout.maximumWidth: app.width - 48
                Layout.columnSpan: gridLayout.columns
                wrapMode: Text.WordWrap
                Layout.bottomMargin: 16

            }
            StyledButton {
                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                Layout.topMargin: 16
                Layout.rightMargin: 12
                Layout.columnSpan: gridLayout.columns
                text: "Set"
                enabled: !!yubiKey.currentDevice && configurationHasChanged() && validCombination()
                onClicked: configureInterfaces()
            }

        }

        /*
        Legacy keys below
        */

        GridLayout {
            id: gridLayoutLegacyKeys
            columns: 2
            rowSpacing: 0
            columnSpacing: 0
            Layout.leftMargin: 0
            Layout.fillWidth: true
            visible: !!yubiKey.currentDevice && !yubiKey.supportsNewInterfaces(yubiKey.currentDevice)

            // header

            Text {
                text: "Interface"
                color: primaryColor
                opacity: lowEmphasis
                font.pixelSize: 12
                Layout.fillWidth: true
            }
            RowLayout {
                spacing: 0
                Layout.margins: 0

                StyledImage {
                    source: "../images/usb.svg"
                    color: primaryColor
                    opacity: lowEmphasis
                    Layout.leftMargin: -24
                    leftInset: 0
                    Layout.margins: 0
                    padding: 0
                    iconWidth: 16
                }
                Text {
                    text: "USB"
                    Layout.leftMargin: -22
                    color: primaryColor
                    opacity: lowEmphasis
                    font.pixelSize: 12
                }
            }

            // Legacy CCID

            Label {
                text: "Smart card (CCID)"
                visible: ccidModeBtn.visible
            }

            CheckBox {
                id: ccidModeBtn
                checked: !!yubiKey.currentDevice && yubiKey.currentDevice.usbInterfacesEnabled.includes("CCID")
                visible: !!yubiKey.currentDevice && yubiKey.currentDevice.usbInterfacesSupported.includes("CCID")
            }

            Label {
                text: "The CCID interface includes smart card, encryption and security codes functionality."
                visible: ccidModeBtn.visible
                color: primaryColor
                opacity: disabledEmphasis
                font.pixelSize: 12
                maximumLineCount: 2
                Layout.maximumWidth: app.width - 48
                Layout.columnSpan: gridLayoutLegacyKeys.columns
                wrapMode: Text.WordWrap
            }

            // Legacy FIDO

            Label {
                text: "WebAuthn (FIDO)"
                visible: fidoModeBtn.visible
            }

            CheckBox {
                id: fidoModeBtn
                checked: !!yubiKey.currentDevice && yubiKey.currentDevice.usbInterfacesEnabled.includes("FIDO")
                visible: !!yubiKey.currentDevice && yubiKey.currentDevice.usbInterfacesSupported.includes("FIDO")
            }

            Label {
                text: "The FIDO protocols are used in the W3C WebAuthn standard adopted by all web browsers."
                visible: fidoModeBtn.visible
                color: primaryColor
                opacity: disabledEmphasis
                font.pixelSize: 12
                maximumLineCount: 2
                Layout.maximumWidth: app.width - 48
                Layout.columnSpan: gridLayoutLegacyKeys.columns
                wrapMode: Text.WordWrap
            }

            // Legacy OTP

            Label {
                text: "OTP"
                visible: otpModeBtn.visible
            }

            CheckBox {
                id: otpModeBtn
                checked: !!yubiKey.currentDevice && yubiKey.currentDevice.usbInterfacesEnabled.includes("OTP")
                visible: !!yubiKey.currentDevice && yubiKey.currentDevice.usbInterfacesSupported.includes("OTP")
            }

            Label {
                text: "Protocols for one-time passwords, challenge response, static passwords etc."
                visible: otpModeBtn.visible
                color: primaryColor
                opacity: disabledEmphasis
                font.pixelSize: 12
                maximumLineCount: 2
                Layout.maximumWidth: app.width - 48
                Layout.columnSpan: gridLayoutLegacyKeys.columns
                wrapMode: Text.WordWrap
            }

            StyledButton {
                Layout.alignment: Qt.AlignRight | Qt.AlignTop
                Layout.topMargin: 16
                Layout.rightMargin: 12
                text: "Set"
                Layout.columnSpan: gridLayoutLegacyKeys.columns
                onClicked: configureModes()
                enabled: !!yubiKey.currentDevice && legacyConfigurationHasChanged() && legacyValidCombination()
            }
        }
    }
}
       }
