import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0
import "utils.js" as Utils

Pane {

    id: credentialCard

    implicitWidth: app.width <= 360 ? app.width : 360

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
                    navigator.forceActiveFocus()
                }
            }
            Menu {
                id: contextMenu
                MenuItem {
                    icon.source: "../images/copy.svg"
                    icon.color: iconButtonNormal
                    icon.width: 20
                    icon.height: 20
                    text: qsTr("Copy to clipboard")
                    onTriggered: calculateCard(true)
                }
                MenuItem {
                    icon.source: "../images/delete.svg"
                    icon.color: iconButtonNormal
                    icon.width: 20
                    icon.height: 20
                    text: "Delete account"
                    onTriggered: deleteCard()
                }
                MenuItem {
                    icon.source: favorite ? "../images/star.svg" : "../images/star_border.svg"
                    icon.color: iconButtonNormal
                    icon.width: 20
                    icon.height: 20
                    text: favorite ? qsTr("Remove as favorite") : qsTr("Set as favorite")
                    onTriggered: toggleFavorite()
                }
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
                    text: qsTr("Add account")
                    onTriggered: yubiKey.scanQr()
                }
                MenuItem {
                    icon.source: "../images/cogwheel.svg"
                    icon.color: iconButtonNormal
                    icon.width: 20
                    icon.height: 20
                    text: qsTr("Settings")
                    onTriggered: navigator.goToSettings()
                }
            }
        }

        ToolTip {
            text: qsTr("Double-click to initiate touch")
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
        navigator.snackBar(qsTr("Code copied to clipboard"))
    }

    function calculateCard(copy) {
        if (touchCredentialNoCode || (hotpCredential
                                      && !hotpCredentialInCoolDown)
                || customPeriodCredentialNoTouch) {
            if (touchCredential) {
                navigator.snackBar(qsTr("Touch your YubiKey"))
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

                        if (copy) {
                            copyCode(resp.code.value)
                        }

                        if (hotpCredential) {
                            coolDownHotpCredential()
                        }

                        entries.updateEntry(resp)
                    } else {
                        if (resp.error_id === 'access_denied') {
                            navigator.snackBarError(qsTr("Touch timed out"))
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
                    qsTr("This will permanently delete the account from the YubiKey, as well as your ability to generate security codes for it. Make sure 2FA has been disabled BEFORE proceeding."),
                    function () {
                        if (settings.otpMode) {
                            yubiKey.otpDeleteCredential(credential,
                                                        function (resp) {
                                                            if (resp.success) {
                                                                if (favorite)
                                                                {
                                                                    toggleFavorite()
                                                                }
                                                                entries.deleteEntry(
                                                                            credential.key)
                                                                navigator.snackBar(
                                                                            qsTr("Account deleted"))
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
                                                             if (favorite)
                                                             {
                                                                 toggleFavorite()
                                                             }
                                                             entries.deleteEntry(
                                                                         credential.key)
                                                             yubiKey.updateNextCalculateAll()
                                                             navigator.snackBar(
                                                                          qsTr("Account deleted"))
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
        onTriggered: navigator.snackBar(qsTr("Touch your YubiKey"))
    }


    Item {

        anchors.fill: parent

        CredentialCardIcon {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            size: 40
            Accessible.ignored: true

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
                id: codeLbl
                font.pixelSize: 24
                color: credentialCardCode
                text: getCodeLblValue()
            }
            Label {
                id: nameLbl
                text: formattedName()
                Layout.maximumWidth: app.width <= 360 ? app.width - 95 : 265
                font.pixelSize: 14
                elide: Text.ElideRight
                color: credentialCardIssuer
            }
            ToolTip {
                text: qsTr(nameLbl.text)
                delay: 1000
                parent: nameLbl
                visible: nameLbl.truncated && credentialCard.hovered
                Material.foreground: toolTipForeground
                Material.background: toolTipBackground
            }
        }

        Accessible.role: Accessible.ListItem
        Accessible.focusable: true
        Accessible.name: (credential.issuer ? credential.issuer : credential.name)
        Accessible.description: getCodeLblValue()

        CredentialCardTimer {
            period: credential && credential.period ? credential.period : 0
            validTo: code && code.valid_to ? code.valid_to : 0
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom
            colorCircle: credentialCardIssuer
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
            iconWidth: 18
            iconHeight: 18
            source: "../images/touch.svg"
            visible: touchCredentialNoCode
            color: credentialCardIssuer
        }

        StyledImage {
            id: hotpIcon
            source: "../images/refresh.svg"
            iconWidth: 20
            iconHeight: 20
            visible: hotpCredential
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            color: hotpCredentialInCoolDown ? credentialCardHOTPCoolDown : credentialCardIssuer
        }
    }
}
