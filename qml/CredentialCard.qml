import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0
import "utils.js" as Utils

Pane {

    id: credentialCard

    implicitWidth: 360
    implicitHeight: 80

    Material.elevation: 0

    property var code
    property var credential

    property bool touchCredentialNoCode: touchCredential && (!code
                                                             || !code.value)
    property bool hotpCredential: (credential
                                   && credential.oath_type === "HOTP")
    property bool hotpCredentialInCoolDown

    property bool customPeriodCredentialNoTouch: (credential.period !== 30
                                                  && credential.oath_type === "TOTP"
                                                  && !touchCredential)
    property bool touchCredential: credential && credential.touch

    background: Rectangle {
        color: if (credentialCard.GridView.isCurrentItem) {
                   return credentialCardCurrentItem
               } else if (cardMouseArea.containsMouse) {
                   return credentialCardHovered
               } else {
                   return credentialCardNormal
               }

        MouseArea {
            id: cardMouseArea
            hoverEnabled: true
            anchors.fill: parent
            onClicked: credentialCard.GridView.isCurrentItem ? credentialCard.GridView.view.currentIndex = -1 : credentialCard.GridView.view.currentIndex = index
            onDoubleClicked: calculateCard(true)
        }
    }

    function getIconLetter() {
        return credential.issuer ? credential.issuer.charAt(
                                       0) : credential.name.charAt(0)
    }

    function formattedCode(code) {
        // Add a space in the code for easier reading.
        if (code !== null) {
            switch (code.length) {
            case 6:
                // 123 123
                return code.slice(0, 3) + " " + code.slice(3)
            case 7:
                // 1234 123
                return code.slice(0, 4) + " " + code.slice(4)
            case 8:
                // 1234 1234
                return code.slice(0, 4) + " " + code.slice(4)
            default:
                return code
            }
        }
    }

    function formattedName() {
        if (credential.issuer) {
            return credential.issuer + " (" + credential.name + ")"
        } else {
            return credential.name
        }
    }

    function copyCode(code) {
        clipBoard.push(code)
        navigator.snackBar("Code copied!")
    }

    function calculateCard(copy) {
        if (touchCredentialNoCode || (hotpCredential
                                      && !hotpCredentialInCoolDown)
                || customPeriodCredentialNoTouch) {
            if (touchCredential) {
                navigator.snackBar("Touch your YubiKey!")
            }
            if (settings.otpMode) {
                yubiKey.otpCalculate(credential, function (resp) {
                    if (resp.success) {
                        entries.updateEntry(resp)
                        if (copy) {
                            copyCode(resp.code.value)
                        }
                    } else {
                        navigator.snackBarError(resp.error_id)
                        console.log(resp.error_id)
                    }
                })
            } else {
                yubiKey.calculate(credential, function (resp) {
                    if (resp.success) {
                        entries.updateEntry(resp)
                        if (copy) {
                            copyCode(resp.code.value)
                        }
                        if (hotpCredential) {
                            coolDownHotpCredential()
                        }
                    } else {
                        navigator.snackBarError(resp.error_id)
                        console.log(resp.error_id)
                    }
                })
            }
        } else {
            copyCode(code.value)
        }
    }

    function clearExpiredCode(key) {
        entries.clearCode(key)
    }

    function deleteCard() {
        navigator.confirm(
                    "Are you sure?",
                    "Do you want to permanently delete the credential from the YubiKey?",
                    function () {
                        if (settings.otpMode) {
                            yubiKey.otpDeleteCredential(credential,
                                                        function (resp) {
                                                            if (resp.success) {
                                                                entries.deleteEntry(
                                                                            credential.key)
                                                                navigator.snackBar(
                                                                            "Credential was deleted")
                                                            } else {
                                                                navigator.snackBarError(
                                                                            resp.error_id)
                                                                console.log(resp.error_id)
                                                            }
                                                        })
                        } else {
                            yubiKey.deleteCredential(credential,
                                                     function (resp) {
                                                         if (resp.success) {
                                                             entries.deleteEntry(
                                                                         credential.key)
                                                             yubiKeyPoller.updateNextCalculateAll()
                                                             navigator.snackBar(
                                                                         "Credential was deleted")
                                                         } else {
                                                             navigator.snackBarError(
                                                                         resp.error_id)
                                                             console.log(resp.error_id)
                                                         }
                                                     })
                        }
                    })
    }

    function getCodeLblValue() {
        if (code && code.value && code.valid_to > Utils.getNow()) {
            return formattedCode(code.value)
        } else if (touchCredential || hotpCredential) {
            return "*** ***"
        } else {
            return ""
        }
    }

    function coolDownHotpCredential() {
        hotpCredentialInCoolDown = true
        hotpCoolDownTimer.start()
    }

    Timer {
        id: hotpCoolDownTimer
        triggeredOnStart: false
        interval: 5000
        onTriggered: hotpCredentialInCoolDown = false
    }

    Item {

        anchors.fill: parent

        CredentialCardIcon {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            size: 40
            letter: getIconLetter()
        }

        ColumnLayout {
            anchors.left: icon.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Label {
                id: codLbl
                font.pixelSize: 24
                color: yubicoGreen
                text: getCodeLblValue()
            }
            Label {
                id: nameLbl
                text: formattedName()
                Layout.maximumWidth: 265
                font.pixelSize: 12
                maximumLineCount: 3
                wrapMode: Text.Wrap
            }
        }

        CredentialCardTimer {
            period: credential && credential.period ? credential.period : 0
            validTo: code && code.valid_to ? code.valid_to : 0
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom
            colorCircle: Material.primary
            visible: code && code.value && credential
                     && credential.oath_type === "TOTP" ? true : false
            onTimesUp: {
                if (touchCredential) {
                    clearExpiredCode(credential.key)
                }
                if (customPeriodCredentialNoTouch) {
                    calculateCard(false)
                }
            }
        }

        StyledImage {
            id: touchIcon
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            iconWidth: 24
            iconHeight: 24
            source: "../images/touch.svg"
            visible: !!(touchCredential && code && !code.value)
            color: yubicoGreen
        }

        StyledImage {
            id: hotpIcon
            source: "../images/refresh.svg"
            iconWidth: 24
            iconHeight: 24
            visible: hotpCredential
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            color: hotpCredentialInCoolDown ? yubicoGrey : yubicoGreen
        }
    }
}
