import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0
import "utils.js" as Utils

Pane {

    id: credentialCard

    property var code
    property var credential

    property bool touchCredentialNoCode: touchCredential && (!code
                                                             || !code.value)
    property bool hotpCredential: !!credential && (credential
                                   && credential.oath_type === "HOTP")

    property bool hotpCredentialInCoolDown

    property bool customPeriodCredentialNoTouch: !!credential  && (credential.period !== 30
                                                  && credential.oath_type === "TOTP"
                                                  && !touchCredential)

    property bool touchCredential: !!credential && credential && credential.touch

    property bool favorite: !!credential ? settings.favorites.includes(credential.key) : false

    Layout.fillHeight: true
    Layout.fillWidth: true

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
        if (!!credential && credential.issuer) {
            return credential.issuer + " (" + credential.name + ")"
        } else if (!!credential) {
            return credential.name
        } else {
            return ""
        }
    }

    function copyCode(code) {
        clipBoard.push(code)
        navigator.snackBar(qsTr("Code copied to clipboard"))

        if (settings.minimizeOnCopy) {
            app.hide()
        }
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
                        if (copy) {
                            copyCode(resp.code.value)
                        }
                        entries.updateEntry(resp)
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
        navigator.confirm({
                    "heading": qsTr("Delete %1 ?").arg(formattedName()),
                    "message": qsTr("This will permanently delete the account from your YubiKey."),
                    "description": qsTr("You will not be able to generate security codes for the account anymore. Make sure 2FA has been disabled before proceeding."),
                    "acceptedCb": function () {
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

    property string codeLabelText: getCodeLblValue()
    property var isKeyChanged: false

    background: Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        Layout.minimumWidth: 299
        Layout.minimumHeight: 75
        width: parent.width - 1
        height: parent.height - 1
        color: yubicoWhite
        opacity: if (credentialCard.GridView.isCurrentItem) {
                   return cardSelectedEmphasis
               } else if (cardMouseArea.containsMouse) {
                   return cardHoveredEmphasis
               } else {
                   return isDark() ? cardNormalEmphasis : 1.0
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
                    icon.color: primaryColor
                    opacity: highEmphasis
                    icon.width: 20
                    icon.height: 20
                    text: qsTr("Copy to clipboard")
                    onTriggered: calculateCard(true)
                }
                MenuItem {
                    icon.source: favorite ? "../images/star.svg" : "../images/star_border.svg"
                    icon.color: primaryColor
                    opacity: highEmphasis
                    icon.width: 20
                    icon.height: 20
                    text: favorite ? qsTr("Remove as favorite") : qsTr("Set as favorite")
                    onTriggered: toggleFavorite()
                }
                MenuSeparator {
                }
                MenuItem {
                    icon.source: "../images/delete.svg"
                    icon.color: primaryColor
                    opacity: highEmphasis
                    icon.width: 20
                    icon.height: 20
                    text: "Delete account"
                    onTriggered: deleteCard()
                }
            }
        }

        ToolTip {
            text: qsTr("Double-click to initiate touch")
            delay: 1000
            parent: credentialCard
            visible: touchCredentialNoCode && parent.hovered && !favoriteBtn.hovered
            Material.foreground: toolTipForeground
            Material.background: toolTipBackground
        }
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
            anchors.leftMargin: 4
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            size: 40
            Accessible.ignored: true
        }

        ColumnLayout {
            anchors.left: icon.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Label {
                id: codeLbl
                font.pixelSize: 24
                color: primaryColor
                opacity: hovered || credentialCard.GridView.isCurrentItem ? fullEmphasis : highEmphasis
                text: getCodeLblValue()
                font.weight: credentialCard.GridView.isCurrentItem ? Font.Normal : Font.Light
            }
            Label {
                id: nameLbl
                text: formattedName()
                Layout.maximumWidth: credentialCard.width - 106
                font.pixelSize: 14
                elide: Text.ElideRight
                color: primaryColor
                opacity: lowEmphasis
            }
            ToolTip {
                text: qsTr(nameLbl.text)
                delay: 1000
                parent: nameLbl
                visible: nameLbl.truncated && credentialCard.hovered && !favoriteBtn.hovered
                Material.foreground: toolTipForeground
                Material.background: toolTipBackground
            }
        }

        Accessible.role: Accessible.ListItem
        Accessible.focusable: true
        Accessible.name: !!credential ? (credential.issuer ? credential.issuer : credential.name) : ""
        Accessible.description: getCodeLblValue()

        ToolButton {
            id: favoriteBtn
            Layout.alignment: Qt.AlignRight | Qt.AlignTop
            visible: favorite || credentialCard.hovered || credentialCard.GridView.isCurrentItem

            anchors.top: parent.top
            anchors.right: parent.right
            anchors.rightMargin: -6
            anchors.topMargin: -2

            onClicked: toggleFavorite()
            Keys.onReturnPressed: toggleFavorite()
            Keys.onEnterPressed: toggleFavorite()
            focusPolicy: Qt.NoFocus

            Accessible.role: Accessible.Button
            Accessible.name: "Favorite"
            Accessible.description: "Favorite credential"

            ToolTip {
                text: favorite ? qsTr("Remove as favorite") : qsTr("Set as favorite")
                delay: 1000
                parent: favoriteBtn
                visible: parent.hovered
                Material.foreground: toolTipForeground
                Material.background: toolTipBackground
            }

            icon.source: favorite ? "../images/star.svg" : "../images/star_border.svg"
            icon.color: hovered || favorite ? iconFavorite : primaryColor
            opacity: hovered || favorite ? highEmphasis : disabledEmphasis
            implicitHeight: 30
            implicitWidth: 30

            MouseArea {
                id: favoriteMouseArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                propagateComposedEvents: true
                enabled: false
            }
        }

        CredentialCardTimer {
            period: credential && credential.period ? credential.period : 0
            validTo: code && code.valid_to ? code.valid_to : 0
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.rightMargin: 3
            anchors.bottomMargin: 6
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom
            visible: code && code.value && credential && credential.oath_type === "TOTP" ? true : false
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
            anchors.rightMargin: 0
            anchors.bottomMargin: 6
            iconWidth: 18
            iconHeight: 18
            source: "../images/touch.svg"
            visible: touchCredentialNoCode
            color: primaryColor
            opacity: lowEmphasis
            Layout.alignment: Qt.AlignRight
        }

        StyledImage {
            id: hotpIcon
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.rightMargin: -1
            anchors.bottomMargin: 2
            iconWidth: 20
            iconHeight: 20
            source: "../images/refresh.svg"
            visible: hotpCredential
            color: primaryColor
            opacity: hotpCredentialInCoolDown ? disabledEmphasis : lowEmphasis
            Layout.alignment: Qt.AlignRight
        }
    }
}

