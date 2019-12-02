import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {

    readonly property int dynamicWidth: 864
    readonly property int dynamicMargin: 32

    id: newCredentialViewId
    objectName: 'newCredentialView'
    property string title: qsTr("Add Account")

    ScrollBar.vertical: ScrollBar {
        width: 8
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        hoverEnabled: true
        z: 2
    }
    boundsBehavior: Flickable.StopAtBounds

    property var credential
    property bool manualEntry

    contentWidth: app.width
    contentHeight: content.implicitHeight + dynamicMargin

    function acceptableInput() {
        // trim spaces to accurately count length, parse_b32_key later trims them
        var secretKeyTrimmed = secretKeyLbl.text.replace(/ /g, "")
        if (settings.otpMode) {
            return secretKeyTrimmed.length > 0 && secretKeyTrimmed.length <= 32
        } else {
            var nameAndKey = nameLbl.text.length > 0
                    && secretKeyTrimmed.length > 0
            var okTotalLength = (nameLbl.text.length + issuerLbl.text.length) < 60
            return nameAndKey && okTotalLength
        }
    }

    function addCredential() {

        function callback(resp) {
            if (resp.success) {
                yubiKey.calculateAll(navigator.goToCredentials)
                if (!settings.hideBackupReminder) {
                    navigator.confirm({
                                          "heading": qsTr("Account added. Create backup?"),
                                          "message": qsTr("Secrets are stored safely on YubiKey. Backups can only be created during setup."),
                                          "description": qsTr("To create a backup, change YubiKey and repeat the 'Add account' procedure BEFORE verifying with the issuer. The secret key may also be copied and stored somewhere safe."),
                                          "warning": false,
                                          "copySecret": true,
                                          "buttons": false,
                                          "acceptedCb": function () {
                                            clipBoard.push(secretKeyLbl.text)
                                            navigator.snackBar(qsTr("Secret copied to clipboard"))
                                        }
                                })
                } else {
                    navigator.snackBar(qsTr("Account added"))
                }
            } else {
                if (resp.error_id === 'credential_already_exists') {
                    navigator.confirm({
                                    "heading": qsTr("Overwrite?"),
                                    "message": qsTr("An account with this name already exists, do you want to overwrite it?"),
                                    "acceptedCb": _ccidAddCredentialOverwrite
                                      })
                } else {
                    navigator.snackBarError(navigator.getErrorMessage(resp.error_id))
                    console.log("addCredential failed:", resp.error_id)
                }
            }
        }

        function _otpAddCredential() {
            yubiKey.otpAddCredential(otpSlotComboBox.currentText,
                                     secretKeyLbl.text,
                                     requireTouchCheckBox.checked, callback)
        }

        function _ccidAddCredential(overwrite) {
            yubiKey.ccidAddCredential(nameLbl.text, secretKeyLbl.text,
                                          issuerLbl.text,
                                          oathTypeComboBox.currentText,
                                          algoComboBox.currentText,
                                          digitsComboBox.currentText,
                                          periodLbl.text,
                                          requireTouchCheckBox.checked,
                                          overwrite,
                                          callback)
        }

        function _ccidAddCredentialOverwrite() {
            _ccidAddCredential(true)
        }

        function _ccidAddCredentialNoOverwrite() {
            _ccidAddCredential(false)
        }

        if (acceptableInput()) {
            if (settings.otpMode) {
                yubiKey.otpSlotStatus(function (resp) {
                    if (resp.success) {
                        if (resp.status[parseInt(
                                            otpSlotComboBox.currentText) - 1]) {
                            navigator.confirm({
                                            "heading": qsTr("Overwrite?"),
                                            "message": qsTr("This slot is already configured, do you want to overwrite it?"),
                                            "acceptedCb": _otpAddCredential
                                              })
                        } else {
                            _otpAddCredential()
                        }
                    } else {
                        navigator.snackBarError(navigator.getErrorMessage(
                                                    resp.error_id))
                    }
                })
            } else {
                _ccidAddCredentialNoOverwrite()
            }
            settings.requireTouch = requireTouchCheckBox.checked
        }
    }


    Keys.onEscapePressed: navigator.home()

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
        anchors.fill: parent
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.leftMargin: 0

        Pane {
            id: content
            Layout.alignment: Qt.AlignCenter | Qt.AlignTop
            Layout.fillWidth: true
            Layout.maximumWidth: dynamicWidth + dynamicMargin
            Layout.topMargin: 0

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
                width: app.width - dynamicMargin
                       < dynamicWidth ? app.width - dynamicMargin : dynamicWidth
                spacing: 0

                StyledStepperContainer {
                    Layout.fillWidth: true
                    initialStep: !manualEntry ? 2 : 1

                    StyledStepperPanel {
                        label: qsTr("Make sure QR code is fully visible")
                        description: qsTr("Press the button to scan when ready.")
                        id: retryPane
                        Layout.fillWidth: true
                        Component.onCompleted: retry.forceActiveFocus()

                        StyledImage {
                            source: "../images/qr-monitor.svg"
                            color: app.isDark() ? defaultLightForeground : defaultLightOverlay
                            iconWidth: 140
                            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                            Layout.margins: 16
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignLeft | Qt.AlignTop

                            StyledButton {
                                id: retry
                                text: qsTr("Scan")
                                toolTipText: qsTr("Scan a QR code on the screen")
                                focus: true
                                onClicked: yubiKey.scanQr(true)
                                Keys.onReturnPressed: yubiKey.scanQr(true)
                                Keys.onEnterPressed: yubiKey.scanQr(true)
                            }
                            StyledButton {
                                text: qsTr("Enter manually")
                                toolTipText: qsTr("Enter account details manually")
                                flat: true
                                onClicked: manualEntryPane.expandAction()
                                Material.foreground: formText
                                Keys.onReturnPressed: manualEntryPane.expandAction()
                                Keys.onEnterPressed: manualEntryPane.expandAction()
                            }
                        }
                    }

                    StyledStepperPanel {
                        label: qsTr("Add account")
                        description: !manualEntry ? qsTr("Edit and confirm settings") : qsTr("Use manual entry if there's no QR code available.")
                        id: manualEntryPane

                        ColumnLayout {
                            Layout.topMargin: 8

                            StyledTextField {
                                id: issuerLbl
                                labelText: qsTr("Issuer")
                                Layout.fillWidth: true
                                text: credential
                                      && credential.issuer ? credential.issuer : ""
                                visible: !settings.otpMode
                                onSubmit: addCredential()
                            }
                            StyledTextField {
                                id: nameLbl
                                labelText: qsTr("Account name")
                                Layout.fillWidth: true
                                required: true
                                text: credential && credential.name ? credential.name : ""
                                visible: !settings.otpMode
                                onSubmit: addCredential()
                            }
                            StyledTextField {
                                id: secretKeyLbl
                                labelText: qsTr("Secret key")
                                Layout.fillWidth: true
                                required: true
                                text: credential
                                      && credential.secret ? credential.secret : ""
                                visible: manualEntry
                                validateText: qsTr("Invalid Base32 format (A-Z and 2-7)")
                                validateRegExp: /^[2-7a-zA-Z ]+[= ]*$/
                                Layout.bottomMargin: 12
                                onSubmit: addCredential()
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                StyledComboBox {
                                    label: qsTr("Slot")
                                    id: otpSlotComboBox
                                    model: getEnabledOtpSlots()
                                }
                                visible: settings.otpMode
                            }

                            RowLayout {
                                CheckBox {
                                    id: requireTouchCheckBox
                                    checked: settings.requireTouch
                                    text: qsTr("Require touch")
                                    padding: 0
                                    indicator.width: 16
                                    indicator.height: 16
                                    Material.foreground: formText
                                    font.pixelSize: 13
                                }
                                visible: yubiKey.supportsTouchCredentials()
                                         || settings.otpMode
                            }

                            StyledExpansionPanel {
                                id: advancedSettingsPanel
                                label: qsTr("Advanced settings")
                                description: qsTr("Changing these may result in unexpected behavior.")
                                visible: manualEntry && !settings.otpMode
                                dropShadow: false
                                backgroundColor: "transparent"

                                ColumnLayout {
                                    Layout.fillWidth: true

                                    RowLayout {

                                        StyledComboBox {
                                            label: "Type"
                                            id: oathTypeComboBox
                                            model: ["TOTP", "HOTP"]
                                            selectedValue: credential && credential.oath_type ? credential.oath_type : ""
                                        }
                                        Item {
                                            width: 16
                                        }
                                        StyledComboBox {
                                            id: algoComboBox
                                            label: qsTr("Algorithm")
                                            model: {
                                                var algos = ["SHA1", "SHA256"]
                                                if (yubiKey.supportsOathSha512()) {
                                                    algos.push("SHA512")
                                                }
                                                return algos
                                            }
                                            selectedValue: credential && credential.algorithm ? credential.algorithm : ""
                                        }
                                    }

                                    RowLayout {

                                        StyledTextField {
                                            id: periodLbl
                                            visible: oathTypeComboBox.currentIndex === 0
                                            labelText: qsTr("Period")
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
                                            label: qsTr("Digits")
                                            model: ["6", "7", "8"]
                                            selectedValue: credential && credential.digits ? credential.digits : ""
                                        }
                                    }
                                }
                            }

                            StyledButton {
                                id: addBtn
                                text: qsTr("Add")
                                toolTipText: qsTr("Add account to YubiKey")
                                enabled: settings.otpMode ? secretKeyLbl.validated && acceptableInput() :  secretKeyLbl.validated && acceptableInput() && nameLbl.validated
                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                onClicked: addCredential()
                                Layout.bottomMargin: -16
                            }
                        }
                    }
                }
            }
        }
    }
}
