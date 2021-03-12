import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0
import QtQuick.Dialogs 1.2
import Qt.labs.platform 1.0
import QtQuick.Window 2.2


Flickable {

    id: newCredentialViewId
    objectName: 'newCredentialView'

    property var credential
    property bool manualEntry: false
    property bool scanning: false
    property var fileName

    property var expandedHeight: content.implicitHeight + dynamicMargin

    Pane {
        id: dropAreaOverlay
        anchors.centerIn: parent
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        width: app.width-8
        height: app.height-toolBar.height-8
        visible: false
        z: 200
        background: Rectangle {
            anchors.fill: parent
            color: isDark() ? "#ee111111" : "#eeeeeeee"
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            anchors.centerIn: parent

            StyledImage {
                id: yubikeys
                source: "../images/qr-scanner.svg"
                color: primaryColor
                opacity: lowEmphasis
                iconWidth: 110
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                bottomPadding: 16
            }

            Label {
                text: qsTr("Drop QR code")
                font.pixelSize: 16
                font.weight: Font.Normal
                lineHeight: 1.5
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                color: primaryColor
                opacity: highEmphasis
            }
            Label {
                text: qsTr("Drag and drop any image containing a QR code here.")
                horizontalAlignment: Qt.AlignHCenter
                Layout.minimumWidth: 300
                Layout.maximumWidth: app.width - dynamicMargin
                                     < dynamicWidthSmall ? app.width - dynamicMargin : dynamicWidthSmall
                Layout.rowSpan: 1
                lineHeight: 1.1
                wrapMode: Text.WordWrap
                font.pixelSize: 13
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                color: primaryColor
                opacity: lowEmphasis
            }
        }
    }

    DropArea {
        id: dropArea;
        anchors.fill: parent
        onEntered: {
            drag.accept (Qt.LinkAction);
            dropAreaOverlay.visible = true
        }
        onExited: dropAreaOverlay.visible = false
        onDropped: {
            dropAreaOverlay.visible = false
            var url = drop.urls[0]
            var file
            if (url.includes("file")) {
                if (Qt.platform.os === "windows") {
                    file = url.replace(/^(file:\/{3})/,"")
                } else {
                    file = url.replace(/^(file:\/{2})/,"")
                }
                scanQr(ScreenShot.capture(file))
            } else {
                scanQr(url)
            }
        }
    }

    onExpandedHeightChanged: {
        if (expandedHeight > app.height - toolBar.height) {
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

    width: app.width
    boundsBehavior: Flickable.StopAtBounds
    contentHeight: app.height-toolBar.height > expandedHeight
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

    function scanQr(data) {
        scanning = true
        yubiKey.parseQr(data, function (resp) {
            scanning = false
            if (resp.success) {
                credential = resp
            } else {
                if (resp.error_id === "failed_to_parse_uri") {
                    navigator.snackBarError(navigator.getErrorMessage('no_credential_found'))
                } else {
                    navigator.snackBarError(navigator.getErrorMessage(
                                                                resp.error_id))
                }
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
                    Keys.onReturnPressed: scanQr(ScreenShot.capture(""))
                    onClicked: scanQr(ScreenShot.capture(""))
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
                visible: manualEntry && !settings.otpMode
                Layout.bottomMargin: 0
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
                primary: true
                text: qsTr("Add account")
                toolTipText: qsTr("Add account to YubiKey")
                enabled: secretKeyLbl.validated && acceptableInput() && nameLbl.validated
                onClicked: addCredential()
            }
        }
    }
}
