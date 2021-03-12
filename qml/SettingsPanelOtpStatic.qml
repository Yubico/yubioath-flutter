import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import QtQuick.Controls.Material 2.2

ColumnLayout {
    property string keyboardLayout: allowNonModhex.checked ? 'US' : 'MODHEX'
    property bool changed: otpStaticPassword.text !== ""

    RowLayout {
        StyledTextField {
            id: otpStaticPassword
            labelText: qsTr("Password")
            validator: allowNonModhex.checked ? usLayoutValidator : modHexValidator
        }

        ToolButton {
            id: btnGenerateSecretKey
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom

            onClicked: generatePassword()
            Keys.onReturnPressed: generatePassword()
            Keys.onEnterPressed: generatePassword()

            Accessible.role: Accessible.Button
            Accessible.name: "Generate"
            Accessible.description: "Generate a random password"

            ToolTip {
                text: qsTr("Generate a random password")
                delay: 1000
                parent: parent
                visible: parent.hovered
                Material.foreground: toolTipForeground
                Material.background: toolTipBackground
            }

            icon.source: "../images/refresh.svg"
            icon.color: primaryColor
            opacity: hovered ? fullEmphasis : lowEmphasis

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: false
            }
        }
    }

    RowLayout {
        CheckBox {
            id: allowNonModhex
            text: qsTr("Allow any character")
            onCheckedChanged: otpStaticPassword.text = ""
            ToolTip.delay: 1000
            ToolTip.visible: hovered
            ToolTip.text: qsTr("By default only modhex characters are allowed, enable this option to allow any (US Layout) characters")
        }
    }


    function generatePassword() {
        yubiKey.generateStaticPw(keyboardLayout, function (resp) {
            if (resp.success) {
                otpStaticPassword.text = resp.password
            } else {
                navigator.snackBarError(
                            navigator.getErrorMessage(
                                resp.error_id))
            }
        })
    }

    RegExpValidator {
        id: modHexValidator
        regExp: /[cbdefghijklnrtuvCBDEFGHIJKLMNRTUV]{1,38}$/
    }

    RegExpValidator {
        id: usLayoutValidator
        regExp: /[ abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!"#\$%&'\\`\(\)\*\+,-\.\/:;<=>\?@\[\]\^_{}\|~]{1,38}$/
    }

    function programStaticPassword(slot) {
        yubiKey.programStaticPassword(slot, otpStaticPassword.text,
                                      keyboardLayout, function (resp) {
                                          if (resp.success) {
                                              navigator.snackBar(
                                                          "Configured static password")
                                          } else {
                                              if (resp.error_id === 'write error') {
                                                  navigator.snackBar(qsTr("Failed to modify. Make sure the YubiKey does not have restricted access."))
                                              } else {
                                                  navigator.snackBarError(
                                                              navigator.getErrorMessage(
                                                                  resp.error_id))
                                              }
                                          }
                                      })
    }
}


