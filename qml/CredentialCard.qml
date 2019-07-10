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

    property bool favorite: settings.favorites.includes(credential.key)
    property bool favoriteDefault: settings.favoriteDefault === credential.key

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
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onDoubleClicked: calculateCard(true)
            onClicked: {
                if (mouse.button === Qt.RightButton) {
                    contextMenu.popup()
                } else {
                    credentialCard.GridView.isCurrentItem ? credentialCard.GridView.view.currentIndex = -1 : credentialCard.GridView.view.currentIndex = index
                }
            }
            Menu {
                id: contextMenu
                MenuItem {
                    icon.source: "../images/copy.svg"
                    icon.color: iconButtonNormal
                    icon.width: 20
                    icon.height: 20
                    text: "Copy to clipboard"
                    onTriggered: calculateCard(true)
                }
                MenuItem {
                    icon.source: "../images/delete.svg"
                    icon.color: iconButtonNormal
                    icon.width: 20
                    icon.height: 20
                    text: "Delete credential"
                    onTriggered: deleteCard()
                }
                MenuItem {
                    icon.source: favorite ? "../images/star.svg" : "../images/star_border.svg"
                    icon.color: iconButtonNormal
                    icon.width: 20
                    icon.height: 20
                    text: favorite ? "Remove as favorite" : "Set as favorite"
                    onTriggered: toggleFavorite()
                }
                /*
                MenuItem {
                    icon.source: favoriteDefault ? "../images/favorite.svg" : "../images/favorite_border.svg"
                    icon.color: iconButtonNormal
                    icon.width: 20
                    icon.height: 20
                    text: favoriteDefault ? "Remove as default" : "Make default"
                    onTriggered: toggleDefault()
                }
                */
                MenuSeparator {
                    padding: 0
                    topPadding: 4
                    bottomPadding: 4
                    contentItem: Rectangle {
                        implicitWidth: 200
                        implicitHeight: 1
                        color: formUnderline
                    }
                }
                MenuItem {
                    icon.source: "../images/add.svg"
                    icon.color: iconButtonNormal
                    icon.width: 20
                    icon.height: 20
                    enabled: !!yubiKey.currentDevice && yubiKey.currentDeviceValidated
                    text: "Add credential"
                    onTriggered: yubiKey.scanQr()
                }
                MenuItem {
                    icon.source: "../images/cogwheel.svg"
                    icon.color: iconButtonNormal
                    icon.width: 20
                    icon.height: 20
                    text: "Settings"
                    onTriggered: navigator.goToSettings()
                }
            }
        }

        ToolTip {
            text: "Double-click to initiate touch required"
            delay: 1000
            parent: credentialCard
            visible: touchCredential && parent.hovered
            Material.foreground: toolTipForeground
            Material.background: toolTipBackground
        }
    }

    function toggleFavorite() {
        if (favorite) {
            settings.favorites = settings.favorites.filter(fav => fav !== credential.key)
        } else {
            let favs = settings.favorites
            favs.push(credential.key)
            settings.favorites = favs
        }
        entries.sort()
    }

    function toggleDefault() {
        if (favoriteDefault) {
            settings.favoriteDefault = ""
        } else {
            settings.favoriteDefault = credential.key
        }
    }

    function getIconLetter() {
        return credential.issuer ? credential.issuer.charAt(
                                       0) : credential.name.charAt(0)
    }

    function formattedCode(code) {
        // Add a space in the code for easier reading.
        if (!!code) {
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
        navigator.snackBar("Code copied to clipboard")
    }

    function calculateCard(copy) {
        if (touchCredentialNoCode || (hotpCredential
                                      && !hotpCredentialInCoolDown)
                || customPeriodCredentialNoTouch) {
            if (touchCredential) {
                navigator.snackBar("Touch your YubiKey")
            }
            if (hotpCredential) {
                hotpTouchTimer.start()
            }

            if (settings.otpMode) {
                yubiKey.otpCalculate(credential, function (resp) {
                    if (resp.success) {
                        hotpTouchTimer.stop()
                        entries.updateEntry(resp)
                        if (copy) {
                            copyCode(resp.code.value)
                        }
                    } else {
                        navigator.snackBarError(resp.error_id)
                        console.log("calculate failed:", resp.error_id)
                    }
                })
            } else {
                yubiKey.calculate(credential, function (resp) {
                    if (resp.success) {
                        hotpTouchTimer.stop()
                        // This should not be needed, but it
                        // makes the UI update instantly.
                        code = resp.code
                        credential = resp.credential

                        entries.updateEntry(resp)

                        if (copy) {
                            copyCode(resp.code.value)
                        }

                        if (hotpCredential) {
                            coolDownHotpCredential()
                        }
                    } else {
                        if (resp.error_id === 'access_denied') {
                            navigator.snackBarError("Touch credential timed out")
                        } else {
                            navigator.snackBarError(navigator.getErrorMessage(
                                                        resp.error_id))
                        }
                        console.log("calculate failed:", resp.error_id)
                    }
                })
            }
        } else {
            copyCode(code.value)
        }
    }

    function clearExpiredCode() {
        code = null // To update UI instantly
        entries.clearCode(credential.key)
    }

    function deleteCard() {
        navigator.confirm(
                    "Delete " + formattedName() + " ?",
                    "This will permanently delete the credential from the YubiKey, and your ability to generate codes for it.",
                    function () {
                        if (settings.otpMode) {
                            yubiKey.otpDeleteCredential(credential,
                                                        function (resp) {
                                                            if (resp.success) {
                                                                entries.deleteEntry(
                                                                            credential.key)
                                                                navigator.snackBar(
                                                                            "Credential deleted")
                                                            } else {
                                                                navigator.snackBarError(
                                                                            resp.error_id)
                                                                console.log("delete failed:", resp.error_id)
                                                            }
                                                        })
                        } else {
                            yubiKey.deleteCredential(credential,
                                                     function (resp) {
                                                         if (resp.success) {
                                                             entries.deleteEntry(
                                                                         credential.key)
                                                             yubiKey.updateNextCalculateAll()
                                                             navigator.snackBar(
                                                                         "Credential deleted")
                                                         } else {
                                                             navigator.snackBarError(
                                                                         resp.error_id)
                                                             console.log("delete failed:", resp.error_id)
                                                         }
                                                     })
                        }
                    })
    }

    function getCodeLblValue() {
        if (!!code && !!code.value && (code.valid_to > Utils.getNow())) {
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

    Timer {
        id: hotpTouchTimer
        triggeredOnStart: false
        interval: 500
        onTriggered: navigator.snackBar("Touch your YubiKey")
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
            StyledImage {
                id: favoriteIcon
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.bottomMargin: -5
                iconWidth: 15
                iconHeight: 15
                source: "../images/star.svg"
                visible: favorite && !favoriteDefault
                color: "#f7bd0c"
            }
            StyledImage {
                id: favoriteDefaultIcon
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.bottomMargin: -5
                iconWidth: 15
                iconHeight: 15
                source: "../images/favorite.svg"
                visible: favoriteDefault
                color: yubicoRed
            }
        }

        ColumnLayout {
            anchors.left: icon.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Label {
                id: codLbl
                font.pixelSize: 24
                color: Material.primary
                text: getCodeLblValue()
            }
            Label {
                id: nameLbl
                text: formattedName()
                Layout.maximumWidth: 265
                font.pixelSize: 12
                maximumLineCount: 3
                wrapMode: Text.Wrap
                color: formText
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
                    clearExpiredCode()
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
            visible: touchCredentialNoCode
            color: Material.primary
        }

        StyledImage {
            id: hotpIcon
            source: "../images/refresh.svg"
            iconWidth: 24
            iconHeight: 24
            visible: hotpCredential
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            color: hotpCredentialInCoolDown ? yubicoGrey : Material.primary
        }
    }
}
