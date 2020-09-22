import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {

    id: newCredentialViewId
    objectName: 'newCredentialView'
    contentWidth: app.width
    contentHeight: content.visible ? expandedHeight : app.height - toolBar.height
    leftMargin: 0
    rightMargin: 0

    property string title: ""
    property var credential

    readonly property int dynamicWidth: 648
    readonly property int dynamicMargin: 32
    property var expandedHeight: content.implicitHeight + dynamicMargin

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

    boundsBehavior: Flickable.StopAtBounds

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
        yubiKey.parseQr(ScreenShot.capture(), function (resp) {
            if (resp.success) {
                navigator.snackBar("QR code found!")
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
                                          toolBar.requireTouchBtn.isSelected,
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
            settings.requireTouch = toolBar.requireTouchBtn.isSelected
        }
    }

    ColumnLayout {
        id: content

        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        spacing: 0
        width: parent.width

        ColumnLayout {
            id: addAccountForm
            width: parent.width
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.topMargin: 8

            Label {
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                text: qsTr("Add account")
                color: Material.primary
                font.pixelSize: 16
                font.weight: Font.Normal
                topPadding: 24
                bottomPadding: 8
                Layout.fillWidth: true
            }
            StyledTextField {
                id: issuerLbl
                labelText: qsTr("Issuer")
                Layout.fillWidth: true
                text: credential
                      && credential.issuer ? credential.issuer : ""
                onSubmit: addCredential()
                Layout.topMargin: 16
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
                validateText: qsTr("Invalid Base32 format (A-Z and 2-7)")
                validateRegExp: /^[2-7a-zA-Z ]+[= ]*$/
                Layout.bottomMargin: 8
                onSubmit: addCredential()
            }

            CheckBox {
                id: requireTouchCheckBox
                checked: settings.requireTouch
                visible: yubiKey.supportsTouchCredentials()
                text: qsTr("Require touch to display code")
                leftPadding: 0
                rightPadding: 6
                Layout.fillWidth: true
                indicator.anchors.right: right
                indicator.anchors.rightMargin: rightPadding
                indicator.opacity: checked ? fullEmphasis : lowEmphasis
                contentItem.anchors.left: left
                contentItem.anchors.leftMargin: leftPadding
                contentItem.opacity: lowEmphasis
                Component.onCompleted: {
                    contentItem.leftPadding = 0
                }
              }
/*            StyledCheckBox {
                id: advancedSettingsCheckBox
                text: qsTr("Show advanced settings")
                description: qsTr("Change according to instructions only.")
                visible: manualEntry
                Layout.bottomMargin: 16
                Layout.topMargin: 0
            }
*/
            StyledExpansionPanel {
                id: advancedSettingsPanel
                label: qsTr("Advanced ")
                description: qsTr("Type, Algorithm, Period, Digits")
                dropShadow: false
                backgroundColor: "transparent"
                Layout.leftMargin: -16
                visible: !credential

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 16

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
