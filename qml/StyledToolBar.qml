import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0
import Qt.labs.platform 1.1

ToolBar {
    id: toolBar

    background: Rectangle {
        color: defaultBackground
        opacity: 0.7
    }

    function getToolbarColor(isActive) {
        if (!isActive) {
            return "transparent"
        } else {
            if (isDark()) {
                return defaultDarkLighter
            } else {
                return "#e7e7e7"
            }
        }
    }

    property bool showSearch: shouldShowSearch()
    property bool showBackBtn: navigator.depth > 1
    property bool showTitleLbl: !!navigator.currentItem
                                && !!navigator.currentItem.title
    property alias searchField: searchField

    function shouldShowSearch() {        
        return !!(navigator.currentItem
                  && navigator.currentItem.objectName === 'credentialsView'
                  && entries.count > 0 && !settings.otpMode)
    }

    function shouldShowSettings() {
        return !!(navigator.currentItem
                  && navigator.currentItem.objectName !== 'settingsView'
                  && navigator.currentItem.objectName !== 'newCredentialView')
    }

    function shouldShowCredentialOptions() {
        return !!(app.currentCredentialCard && navigator.currentItem
                  && navigator.currentItem.objectName === 'credentialsView')
    }

    RowLayout {
        spacing: 0
        anchors.fill: parent

        ToolButton {
            id: backBtn
            visible: showBackBtn
            onClicked: navigator.home()
            icon.source: "../images/back.svg"
            icon.color: hovered ? iconButtonHovered : iconButtonNormal
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: false
            }
        }

        Label {
            id: titleLbl
            visible: showTitleLbl
            text: showTitleLbl ? navigator.currentItem.title : ""
            font.pixelSize: 16
            Layout.leftMargin: -32
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            Layout.fillWidth: true
            color: iconButtonNormal
        }

        ToolButton {
            id: searchBtn
            visible: showSearch
            Layout.leftMargin: 8
            Layout.minimumHeight: 30
            Layout.maximumHeight: 30
            Layout.maximumWidth: 400
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            background: Rectangle {
                color: getToolbarColor(searchBtn.hovered)
                height: 30
                radius: 4
            }

            TextField {
                id: searchField
                visible: showSearch
                selectByMouse: true
                selectedTextColor: defaultBackground
                Layout.fillWidth: true
                Layout.fillHeight: true
                placeholderText: "Quick Find"
                placeholderTextColor: hovered || focus ? iconButtonHovered : iconButtonNormal
                leftPadding: 28
                rightPadding: 8
                width: parent.width
                horizontalAlignment: Qt.AlignLeft
                verticalAlignment: Qt.AlignVCenter
                color: hovered || focus ? iconButtonHovered : iconButtonNormal
                background: Rectangle {
                    color: getToolbarColor(searchField.focus)
                    height: 30
                    radius: 4
                    opacity: 0.8
                }

                onTextChanged: forceActiveFocus()

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.IBeamCursor
                    onClicked: {
                        contextMenu.open();
                    }
                    onPressAndHold: {
                        if (mouse.source === Qt.MouseEventNotSynthesized) {
                            contextMenu.open();
                        }
                    }
                }

                Menu {
                    id: contextMenu

                    MenuItem {
                        text: "Cut"
                        onTriggered: {
                            searchField.cut()
                        }
                    }
                    MenuItem {
                        text: "Copy"
                        onTriggered: {
                            searchField.copy()
                        }
                    }
                    MenuItem {
                        text: "Paste"
                        onTriggered: {
                            searchField.paste()
                        }
                    }
                }

                function exitSearchMode(clearInput) {
                    if (clearInput) {
                        text = ""
                    }
                    focus = false
                    Keys.forwardTo = navigator
                    navigator.forceActiveFocus()
                }

                KeyNavigation.tab: shouldShowCredentialOptions(
                                       ) ? copyCredentialBtn : addCredentialBtn

                Keys.onEscapePressed: exitSearchMode(true)
                Keys.onDownPressed: exitSearchMode(false)
                Keys.onReturnPressed: {
                    if (currentCredentialCard) {
                        currentCredentialCard.calculateCard(true)
                    }
                }
                Keys.onEnterPressed: {
                    if (currentCredentialCard) {
                        currentCredentialCard.calculateCard(true)
                    }
                }

                StyledImage {
                    id: searchIcon
                    x: 5
                    y: 6
                    iconHeight: 20
                    iconWidth: 20
                    source: "../images/search.svg"
                    color: searchField.hovered || searchField.focus ? iconButtonHovered : iconButtonNormal
                }
            }
        }

        RowLayout {
            spacing: 0
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

            ToolButton {
                id: copyCredentialBtn
                visible: shouldShowCredentialOptions()
                enabled: shouldShowCredentialOptions()
                         && !app.currentCredentialCard.hotpCredentialInCoolDown
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                onClicked: app.currentCredentialCard.calculateCard(true)

                Keys.onReturnPressed: app.currentCredentialCard.calculateCard(
                                          true)
                Keys.onEnterPressed: app.currentCredentialCard.calculateCard(
                                         true)

                KeyNavigation.left: searchField
                KeyNavigation.right: deleteCredentialBtn
                KeyNavigation.tab: deleteCredentialBtn

                ToolTip {
                    text: "Copy code to clipboard"
                    delay: 1000
                    parent: copyCredentialBtn
                    visible: parent.hovered
                    Material.foreground: toolTipForeground
                    Material.background: toolTipBackground
                }

                icon.source: "../images/copy.svg"
                icon.color: hovered ? iconButtonHovered : iconButtonNormal

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: false
                }
            }

            ToolButton {
                id: deleteCredentialBtn
                visible: shouldShowCredentialOptions()
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                onClicked: app.currentCredentialCard.deleteCard()

                Keys.onReturnPressed: app.currentCredentialCard.deleteCard()
                Keys.onEnterPressed: app.currentCredentialCard.deleteCard()

                KeyNavigation.left: copyCredentialBtn
                KeyNavigation.right: favoriteBtn
                KeyNavigation.tab: favoriteBtn

                ToolTip {
                    text: "Delete credential"
                    delay: 1000
                    parent: deleteCredentialBtn
                    visible: parent.hovered
                    Material.foreground: toolTipForeground
                    Material.background: toolTipBackground
                }

                icon.source: "../images/delete.svg"
                icon.color: hovered ? iconButtonHovered : iconButtonNormal

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: false
                }
            }

            ToolButton {
                id: favoriteBtn
                visible: shouldShowCredentialOptions()
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                onClicked: app.currentCredentialCard.toggleFavorite()
                Keys.onReturnPressed: app.currentCredentialCard.toggleFavorite()
                Keys.onEnterPressed: app.currentCredentialCard.toggleFavorite()
                KeyNavigation.left: deleteCredentialBtn
                KeyNavigation.right: settingsBtn
                KeyNavigation.tab: settingsBtn

                ToolTip {
                    text: shouldShowCredentialOptions()
                          && app.currentCredentialCard.favorite ? "Remove as favorite" : "Set as favorite"
                    delay: 1000
                    parent: favoriteBtn
                    visible: parent.hovered
                    Material.foreground: toolTipForeground
                    Material.background: toolTipBackground
                }

                icon.source: shouldShowCredentialOptions()
                             && app.currentCredentialCard.favorite ? "../images/star.svg" : "../images/star_border.svg"
                icon.color: hovered ? iconButtonHovered : iconButtonNormal

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: false
                }
            }

            ToolButton {
                id: addCredentialBtn
                visible: !!yubiKey.currentDevice
                         && yubiKey.currentDeviceValidated
                         && navigator.currentItem
                         && navigator.currentItem.objectName === 'credentialsView'
                         && !app.currentCredentialCard

                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                onClicked: yubiKey.scanQr()
                Keys.onReturnPressed: yubiKey.scanQr()
                Keys.onEnterPressed: yubiKey.scanQr()

                KeyNavigation.left: searchField
                KeyNavigation.right: settingsBtn
                KeyNavigation.tab: settingsBtn

                ToolTip {
                    text: "Add a new credential"
                    delay: 1000
                    parent: addCredentialBtn
                    visible: parent.hovered
                    Material.foreground: toolTipForeground
                    Material.background: toolTipBackground
                }

                icon.source: "../images/add.svg"
                icon.color: hovered ? iconButtonHovered : iconButtonNormal

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: false
                }
            }

            ToolButton {
                id: settingsBtn
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                visible: shouldShowSettings()
                onClicked: navigator.goToSettings()

                Keys.onReturnPressed: navigator.goToSettings()
                Keys.onEnterPressed: navigator.goToSettings()

                KeyNavigation.left: shouldShowCredentialOptions(
                                        ) ? favoriteBtn : addCredentialBtn
                KeyNavigation.right: navigator
                KeyNavigation.tab: navigator

                ToolTip {
                    text: "Settings"
                    delay: 1000
                    parent: settingsBtn
                    visible: parent.hovered
                    Material.foreground: toolTipForeground
                    Material.background: toolTipBackground
                }

                icon.source: "../images/cogwheel.svg"
                icon.color: hovered ? iconButtonHovered : iconButtonNormal

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: false
                }
            }
        }
    }
}
