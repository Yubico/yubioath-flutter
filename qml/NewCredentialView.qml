import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ScrollView {

    readonly property int dynamicWidth: 864
    readonly property int dynamicMargin: 32

    id: newCredentialViewId
    objectName: 'newCredentialView'
    property string title: "New credential"

    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.width: 8

    property var credential
    property bool manualEntry

    contentWidth: app.width
    contentHeight: content.implicitHeight

    function acceptableInput() {
        if (settings.otpMode) {
            return secretKeyLbl.text.length > 0
            // TODO: check maxlength of secret, 20 bytes?
        } else {
            var nameAndKey = nameLbl.text.length > 0
                    && secretKeyLbl.text.length > 0
            var okTotalLength = (nameLbl.text.length + issuerLbl.text.length) < 60
            return nameAndKey && okTotalLength
        }
    }

    function addCredential() {

        function callback(resp) {
            if (resp.success) {
                yubiKey.calculateAll(navigator.goToCredentials)
                navigator.snackBar("Credential added")
            } else {
                navigator.snackBarError(navigator.getErrorMessage(
                                            resp.error_id))
                console.log("addCredential failed:", resp.error_id)
            }
        }

        function _otpAddCredential() {
            yubiKey.otpAddCredential(otpSlotComboBox.currentText,
                                     secretKeyLbl.text,
                                     requireTouchCheckBox.checked, callback)
        }

        if (acceptableInput()) {
            if (settings.otpMode) {
                yubiKey.otpSlotStatus(function (resp) {
                    if (resp.success) {
                        if (resp.status[parseInt(
                                            otpSlotComboBox.currentText) - 1]) {
                            navigator.confirm(
                                        "Overwrite?",
                                        "The slot is already configured, do you want to overwrite it?",
                                        _otpAddCredential)
                        } else {
                            _otpAddCredential()
                        }
                    } else {
                        navigator.snackBarError(navigator.getErrorMessage(
                                                    resp.error_id))
                    }
                })
            } else {
                yubiKey.ccidAddCredential(nameLbl.text, secretKeyLbl.text,
                                          issuerLbl.text,
                                          oathTypeComboBox.currentText,
                                          algoComboBox.currentText,
                                          digitsComboBox.currentText,
                                          periodLbl.text,
                                          requireTouchCheckBox.checked, callback)
            }
            settings.requireTouch = requireTouchCheckBox.checked
        }
    }


    Keys.onEscapePressed: navigator.home()

    Component.onCompleted: retry.forceActiveFocus()

    spacing: 8
    padding: 0

    function getEnabledOtpSlots() {
        var res = []
        if (settings.slot1digits) {
            res.push(1)
        }
        if (settings.slot2digits) {
            res.push(2)
        }
        return res
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        Layout.fillHeight: true
        Layout.fillWidth: true
        spacing: 0

        Pane {
            id: retryPane
            visible: manualEntry
            Layout.alignment: Qt.AlignCenter | Qt.AlignTop
            Layout.fillWidth: true
            Layout.maximumWidth: dynamicWidth + dynamicMargin
            Layout.bottomMargin: 16
            Layout.topMargin: 32
            background: Rectangle {
                color: isDark() ? defaultDarkLighter : defaultLightDarker
                layer.enabled: true
                layer.effect: DropShadow {
                    radius: 3
                    samples: radius * 2
                    verticalOffset: 2
                    horizontalOffset: 0
                    color: formDropShdaow
                    transparentBorder: true
                }
            }
            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                width: app.width - dynamicMargin
                       < dynamicWidth ? app.width - dynamicMargin : dynamicWidth
                spacing: 8
                RowLayout {
                    Label {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        text: "Automatic (recommended)"
                        color: Material.primary
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        topPadding: 8
                        bottomPadding: 16
                        Layout.fillWidth: true
                    }
                }
                Label {
                    text: "1. Make sure the QR code is fully visible on screen"
                    font.pixelSize: 13
                    font.bold: false
                    color: formText
                    Layout.fillWidth: true
                }
                Label {
                    text: "2. Click the Scan button"
                    font.pixelSize: 13
                    font.bold: false
                    color: formText
                    Layout.fillWidth: true
                }
                StyledButton {
                    id: retry
                    text: "Scan"
                    toolTipText: "Scan a QR code on the screen"
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    focus: true
                    enabled: manualEntry
                    onClicked: yubiKey.scanQr(true)
                    Keys.onReturnPressed: yubiKey.scanQr(true)
                    Keys.onEnterPressed: yubiKey.scanQr(true)
                }
            }
        }

        StyledExpansionPanel {
            isSectionTitle: true
            label: !manualEntry ? "" : "Manual Entry"
            description: !manualEntry ? "" : "Use manual entry if there's no QR code available or more advanced configuration is needed."
            Layout.topMargin: !manualEntry ? 32 : 0
            isTopPanel: true
            isExpanded: !manualEntry
            isEnabled: manualEntry
            id: manualEntryPane

            ColumnLayout {

                StyledTextField {
                    id: issuerLbl
                    labelText: "Issuer"
                    Layout.fillWidth: true
                    text: credential
                          && credential.issuer ? credential.issuer : ""
                    visible: !settings.otpMode
                    onSubmit: addCredential()
                }
                StyledTextField {
                    id: nameLbl
                    labelText: "Account name"
                    Layout.fillWidth: true
                    required: true
                    text: credential && credential.name ? credential.name : ""
                    visible: !settings.otpMode
                    onSubmit: addCredential()
                }
                StyledTextField {
                    id: secretKeyLbl
                    labelText: "Secret key"
                    Layout.fillWidth: true
                    required: true
                    text: credential
                          && credential.secret ? credential.secret : ""
                    visible: manualEntry
                    validateText: "Invalid Base32 format (valid characters are A-Z and 2-7)"
                    validateRegExp: /^[2-7a-zA-Z]+=*$/
                    Layout.bottomMargin: 12
                    onSubmit: addCredential()
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledComboBox {
                        label: "Slot"
                        id: otpSlotComboBox
                        model: getEnabledOtpSlots()
                    }
                    visible: settings.otpMode
                }

                RowLayout {
                    CheckBox {
                        id: requireTouchCheckBox
                        checked: settings.requireTouch
                        text: "Require touch"
                        padding: 0
                        indicator.width: 16
                        indicator.height: 16
                        Material.foreground: formText
                    }
                    visible: yubiKey.supportsTouchCredentials()
                             || settings.otpMode
                }

                StyledExpansionPanel {
                    id: advancedSettingsPanel
                    label: "Advanced settings"
                    description: "Normally these settings should not be changed, doing so may result in the code not working as expected."
                    visible: manualEntry && !settings.otpMode
                    dropShadow: false

                    ColumnLayout {
                        Layout.fillWidth: true

                        RowLayout {

                            StyledComboBox {
                                label: "Type"
                                id: oathTypeComboBox
                                model: ["TOTP", "HOTP"]
                                defaultValue: credential && credential.oath_type ? credential.oath_type : ""
                            }
                            Item {
                                width: 16
                            }
                            StyledComboBox {
                                id: algoComboBox
                                label: "Algorithm"
                                model: {
                                    var algos = ["SHA1", "SHA256"]
                                    if (yubiKey.supportsOathSha512()) {
                                        algos.push("SHA512")
                                    }
                                    return algos
                                }
                                defaultValue: credential && credential.algorithm ? credential.algorithm : ""
                            }
                        }

                        RowLayout {

                            StyledTextField {
                                id: periodLbl
                                visible: oathTypeComboBox.currentIndex === 0
                                labelText: "Period"
                                text: credential && credential.period ? credential.period : "30"
                                horizontalAlignment: Text.Alignleft
                                validator: IntValidator {
                                    bottom: 15
                                    top: 60
                                }
                            }
                            Item {
                                visible: oathTypeComboBox.currentIndex === 0
                                width: 16
                            }
                            StyledComboBox {
                                id: digitsComboBox
                                label: "Digits"
                                model: ["6", "7", "8"]
                                defaultValue: credential && credential.digits ? credential.digits : ""
                            }
                        }
                    }
                }

                StyledButton {
                    id: addBtn
                    text: "Add"
                    toolTipText: "Add credential to YubiKey"
                    enabled: settings.otpMode ? secretKeyLbl.validated && acceptableInput() :  secretKeyLbl.validated && acceptableInput() && nameLbl.validated
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    onClicked: addCredential()
                }
            }
        }
    }
}
