import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ScrollView {

    readonly property int dynamicWidth: 600
    readonly property int dynamicMargin: 32

    objectName: 'newCredentialView'
    property string title: "New credential"

    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical: ScrollBar {
        interactive: true
        width: 5
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
    }

    property var credential
    property bool manualEntry
    property bool showAdvanced: false
    contentWidth: app.width


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
        if (settings.otpMode) {
            yubiKey.otpAddCredential(otpSlotComboBox.currentText,
                                     secretKeyLbl.text,
                                     requireTouchCheckBox.checked,
                                     function (resp) {
                                         if (resp.success) {
                                             yubiKeyPoller.calculateAll(
                                                         navigator.goToCredentials)
                                             navigator.snackBar(
                                                         "Credential added")
                                         } else {
                                             navigator.snackBarError(
                                                         navigator.getErrorMessage(
                                                             resp.error_id))
                                             console.log("otpAddCredential failed:",
                                                         resp.error_id)
                                         }
                                     })
        } else {

            yubiKey.addCredential(nameLbl.text, secretKeyLbl.text,
                                  issuerLbl.text, oathTypeComboBox.currentText,
                                  algoComboBox.currentText,
                                  digitsComboBox.currentText, periodLbl.text,
                                  requireTouchCheckBox.checked,
                                  function (resp) {
                                      if (resp.success) {
                                          yubiKeyPoller.calculateAll(
                                                      navigator.goToCredentials)
                                          navigator.snackBar("Credential added")
                                      } else {
                                          navigator.snackBarError(
                                                      navigator.getErrorMessage(
                                                          resp.error_id))
                                          console.log("addCredential failed:",
                                                      resp.error_id)
                                      }
                                  })
        }
    }

    spacing: 8
    padding: 0

    ColumnLayout {
        id: content
        anchors.fill: parent
        Layout.fillHeight: true
        Layout.fillWidth: true
        Pane {
            id: retryPane
            visible: manualEntry
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.fillWidth: true
            Layout.bottomMargin: 16
            background: Rectangle {
                color: isDark() ? defaultDarkLighter : defaultLightDarker
                layer.enabled: true
                layer.effect: DropShadow {
                    radius: 4
                    samples: radius * 2
                    verticalOffset: 2
                    horizontalOffset: 2
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
                        color: yubicoGreen
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        topPadding: 8
                        bottomPadding: 8
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
                    text: "2. Click the Scan QR code button"
                    font.pixelSize: 13
                    font.bold: false
                    color: formText
                    Layout.fillWidth: true
                }
                StyledButton {
                    id: retry
                    text: "Scan"
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    onClicked: yubiKey.scanQr(true)
                }
            }
        }

        Pane {
            id: manualEntryPane
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.topMargin: 8
            Layout.bottomMargin: 8

            background: Rectangle {
        color: isDark() ? defaultDarkLighter : defaultLightDarker
        layer.enabled: true
        layer.effect: DropShadow {
            radius: 4
            samples: radius * 2
            verticalOffset: 2
            horizontalOffset: 2
            color: formDropShdaow
            transparentBorder: true
        }
    }

            ColumnLayout {
                anchors.horizontalCenter: parent.horizontalCenter
                width: app.width - dynamicMargin
                       < dynamicWidth ? app.width - dynamicMargin : dynamicWidth
                spacing: 16
                RowLayout {
                    Label {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        text: "Manual entry"
                        color: yubicoGreen
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        topPadding: 8
                        bottomPadding: 8
                    }
                }

                StyledTextField {
                    id: issuerLbl
                    labelText: "Issuer"
                    Layout.fillWidth: true
                    text: credential && credential.issuer ? credential.issuer : ""
                    visible: !settings.otpMode
                }
                StyledTextField {
                    id: nameLbl
                    labelText: "Account name"
                    Layout.fillWidth: true
                    text: credential && credential.name ? credential.name : ""
                    visible: !settings.otpMode
                }
                StyledTextField {
                    id: secretKeyLbl
                    labelText: "Secret key"
                    Layout.fillWidth: true
                    text: credential && credential.secret ? credential.secret : ""
                    visible: manualEntry
                    validator: RegExpValidator {
                        regExp: /[2-7a-zA-Z ]+=*/
                    }
                }

                RowLayout {
                    Label {
                        text: "Require touch"
                        Layout.fillWidth: true
                    }
                    CheckBox {
                        id: requireTouchCheckBox
                    }
                    visible: yubiKey.supportsTouchCredentials() || settings.otpMode
                }
                RowLayout {
                    Layout.fillWidth: true
                    StyledComboBox {
                        label: "Slot"
                        id: otpSlotComboBox
                        model: [1, 2]
                    }
                    visible: settings.otpMode
                }

                RowLayout {
                    Layout.fillWidth: true
                    StyledComboBox {
                        label: "Type"
                        id: oathTypeComboBox
                        model: ["TOTP", "HOTP"]
                    }
                    visible: manualEntry && showAdvanced && !settings.otpMode
                }
                RowLayout {
                    StyledComboBox {
                        id: digitsComboBox
                        label: "Digits"
                        model: ["6", "7", "8"]
                    }
                    visible: manualEntry && showAdvanced && !settings.otpMode
                }
                RowLayout {
                    Layout.fillWidth: true
                    StyledComboBox {
                        id: algoComboBox
                        label: "Algorithm"
                        model: ["SHA1", "SHA256", "SHA512"]
                    }
                    visible: manualEntry && showAdvanced && !settings.otpMode
                }

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: "Period"
                        Layout.fillWidth: true
                    }
                    StyledTextField {
                        id: periodLbl
                        labelText: "Period"
                        Layout.fillWidth: false
                        text: "30"
                        implicitWidth: 50
                        horizontalAlignment: Text.AlignHCenter
                        validator: IntValidator {
                            bottom: 15
                            top: 60
                        }
                    }
                    visible: manualEntry && showAdvanced && !settings.otpMode
                }
                RowLayout {
                    ToolButton {
                        id: showAdvancedBtn
                        onClicked: showAdvanced ? showAdvanced = false : showAdvanced = true
                        icon.width: 24
                        icon.source: showAdvanced ? "../images/up.svg" : "../images/down.svg"
                        icon.color: isDark() ? yubicoWhite : yubicoGrey
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: false
                        }
                    }

                    Label {
                        text: showAdvanced ? "Show less settings" : "Show more settings"
                        elide: Label.ElideRight
                        horizontalAlignment: Qt.AlignHLeft
                        verticalAlignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                    }
                    visible: manualEntry && !settings.otpMode
                }

                StyledButton {
                    id: addBtn
                    text: "Add"
                    enabled: acceptableInput()
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    onClicked: addCredential()
                }
            }
        }
    }
}
