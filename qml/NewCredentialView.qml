import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {

    readonly property int dynamicWidth: 648
    readonly property int dynamicMargin: 32

    id: newCredentialViewId
    objectName: 'newCredentialView'

    property string title: ""
    property var credential
    property bool manualEntry: false
    property bool scanning: false

    ScrollBar.vertical: ScrollBar {
        width: 8
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        hoverEnabled: true
        z: 2
    }

    width: app.width
    boundsBehavior: Flickable.StopAtBounds
    contentHeight: app.height-toolBar.height > content.implicitHeight + dynamicMargin
                   ? app.height-toolBar.height
                   : content.implicitHeight + dynamicMargin

    Keys.onEscapePressed: navigator.goToAuthenticator()

    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        onClicked: {
            forceActiveFocus()
        }
    }

    function acceptableInput() {
        // trim spaces to accurately count length, parse_b32_key later trims them
        var secretKeyTrimmed = secretKeyLbl.text.replace(/ /g, "")
        var nameAndKey = nameLbl.text.length > 0
                    && secretKeyTrimmed.length > 0
        var okTotalLength = (nameLbl.text.length + issuerLbl.text.length) < 60
        return nameAndKey && okTotalLength
    }

    function scanQr() {
        scanning = true
        currentCredentialCard = null
        yubiKey.parseQr(ScreenShot.capture(), function (resp) {
            scanning = false
            if (resp.success) {
                credential = resp
            } else {
                navigator.snackBarError(navigator.getErrorMessage(
                                                                resp.error_id))
            }
        })
    }

    function addCredentialNoCopy() {
        addCredential(true)
    }

    function addCredential(copy = false) {

        function callback(resp) {
            if (resp.success) {
                    navigator.goToAuthenticator()
                    navigator.snackBar(qsTr("Account added"))
            } else {
                if (resp.error_id === 'credential_already_exists') {
                    navigator.confirm({
                                    "heading": qsTr("Overwrite?"),
                                    "message": qsTr("An account with this name already exists, do you want to overwrite it?"),
                                    "buttonAccept": qsTr("Overwrite"),
                                    "acceptedCb": _ccidAddCredentialOverwrite
                                      })
                } else {
                    navigator.snackBarError(navigator.getErrorMessage(resp.error_id))
                    console.log("addCredential failed:", resp.error_id)
                }
            }
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
             _ccidAddCredentialNoOverwrite()
            settings.requireTouch = requireTouchCheckBox.checked
        }
    }

    ColumnLayout {
        id: content

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        spacing: 4
        width: app.width - dynamicMargin < dynamicWidth
               ? app.width - dynamicMargin
               : dynamicWidth

        Label {
            text: qsTr("Add account (%1/2)").arg(credential || manualEntry ? "2" : "1")
            font.pixelSize: 16
            font.weight: Font.Normal
            lineHeight: 1.8
            color: yubicoGreen
            opacity: fullEmphasis
            Layout.topMargin: 16
            Layout.bottomMargin: 8
        }

        ColumnLayout {
            id: selectScanOrManual
            visible: !credential && !manualEntry
            width: parent.width
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            StyledImage {
                id: qrImage
                source: "../images/qr-monitor.svg"
                color: primaryColor
                opacity: lowEmphasis
                iconWidth: 100
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.topMargin: 8
                visible: !scanning
            }

            Item {
                height: qrImage.height
                width: qrImage.width
                visible: scanning
                Layout.topMargin: 8
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                BusyIndicator {
                    width: 40
                    height: 40
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            Label {
                Layout.topMargin: 16
                text: "To add an account follow the instructions provided by the service. Make sure the QR code is fully visible."
                color: primaryColor
                opacity: highEmphasis
                font.pixelSize: 13
                lineHeight: 1.2
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.maximumWidth: parent.width > 400 ? 400 : parent.width
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.topMargin: 16

                StyledButton {
                    id: btnAccept
                    text: qsTr("Scan QR code on screen")
                    primary: true
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    KeyNavigation.tab: btnCancel
                    Keys.onReturnPressed: scanQr()
                    onClicked: scanQr()
                }

                StyledButton {
                    id: btnCancel
                    text: qsTr("Manual mode")
                    flat: true
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    KeyNavigation.tab: btnAccept
                    Keys.onReturnPressed: manualEntry = true
                    onClicked: manualEntry = true
                }
            }
        }

        ColumnLayout {
            id: addAccountForm
            visible: credential || manualEntry

            StyledTextField {
                id: issuerLbl
                labelText: qsTr("Issuer")
                Layout.fillWidth: true
                text: credential
                      && credential.issuer ? credential.issuer : ""
                onSubmit: addCredential()
            }
            StyledTextField {
                id: nameLbl
                labelText: qsTr("Account name")
                Layout.fillWidth: true
                required: true
                text: credential && credential.name ? credential.name : ""
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
                Layout.bottomMargin: 8
                onSubmit: addCredential()
                KeyNavigation.tab: requireTouchCheckBox
            }

            StyledCheckBox {
                id: requireTouchCheckBox
                checked: settings.requireTouch
                text: qsTr("Require touch")
                description: qsTr("Touch YubiKey to display code.")
                visible: yubiKey.supportsTouchCredentials()
                Layout.bottomMargin: 8
                Layout.topMargin: 0
                KeyNavigation.tab: advancedSettingsCheckBox
            }

            StyledCheckBox {
                id: advancedSettingsCheckBox
                text: qsTr("Show advanced settings")
                description: qsTr("Change according to instructions only.")
                visible: manualEntry
                Layout.bottomMargin: 16
                Layout.topMargin: 0
            }


            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 16
                visible: advancedSettingsCheckBox.checked

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
                        Layout.maximumWidth: oathTypeComboBox.width
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

            StyledButton {
                id: addBtn
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.topMargin: 16
                text: qsTr("Add account")
                toolTipText: qsTr("Add account to YubiKey")
                enabled: secretKeyLbl.validated && acceptableInput() && nameLbl.validated
                onClicked: addCredential()
            }
        }
    }
}
