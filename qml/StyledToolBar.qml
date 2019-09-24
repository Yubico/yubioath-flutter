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
                return "#e8e8e9"
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
                  && !shouldShowCredentialOptions()
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
            font.pixelSize: Qt.application.font.pixelSize * 1.2
            Layout.leftMargin: backBtn.visible ? -32 : 0
            Layout.rightMargin: shouldShowSettings() ? -80 : 0
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            Layout.fillWidth: true
            color: iconButtonNormal
        }

        ToolButton {
            id: searchBtn
            visible: showSearch
            Layout.leftMargin: 8
            Layout.minimumHeight: 30
            Layout.maximumHeight: 30
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
                placeholderText: qsTr("Quick Find")
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

                Accessible.role: Accessible.EditableText
                Accessible.searchEdit: true
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
                        text: qsTr("Cut")
                        onTriggered: {
                            searchField.cut()
                        }
                    }
                    MenuItem {
                        text: qsTr("Copy")
                        onTriggered: {
                            searchField.copy()
                        }
                    }
                    MenuItem {
                        text: qsTr("Paste")
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
                Keys.onReturnPressed: app.currentCredentialCard.calculateCard(true)
                Keys.onEnterPressed: app.currentCredentialCard.calculateCard(true)

                KeyNavigation.left: searchField
                KeyNavigation.right: deleteCredentialBtn
                KeyNavigation.tab: deleteCredentialBtn

                Accessible.role: Accessible.Button
                Accessible.name: "Copy"
                Accessible.description: "Copy to clipboard"

                ToolTip {
                    text: qsTr("Copy code to clipboard")
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

                Accessible.role: Accessible.Button
                Accessible.name: "Delete"
                Accessible.description: "Delete credential"

                ToolTip {
                    text: qsTr("Delete credential")
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

                Accessible.role: Accessible.Button
                Accessible.name: "Favorite"
                Accessible.description: "Favorite credential"

                ToolTip {
                    text: shouldShowCredentialOptions()
                          && app.currentCredentialCard.favorite ? qsTr("Remove as favorite") : qsTr("Set as favorite")
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

                Accessible.role: Accessible.Button
                Accessible.name: "Add"
                Accessible.description: "Add credential"

                ToolTip {
                    text: qsTr("Add a new credential")
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

                KeyNavigation.left: addCredentialBtn
                KeyNavigation.right: moreBtn
                KeyNavigation.tab: moreBtn

                Accessible.role: Accessible.Button
                Accessible.name: "Settings"
                Accessible.description: "Go to settings"

                ToolTip {
                    text: qsTr("Settings")
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

            ToolButton {
                id: moreBtn
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                visible: shouldShowSettings()
                onClicked: navigator.about()

                Keys.onReturnPressed: navigator.about()
                Keys.onEnterPressed: navigator.about()

                KeyNavigation.left: settingsBtn
                KeyNavigation.right: navigator
                KeyNavigation.tab: navigator

                Accessible.role: Accessible.Button
                Accessible.name: "Info"
                Accessible.description: "Information"

                ToolTip {
                    text: qsTr("Information")
                    delay: 1000
                    parent: moreBtn
                    visible: parent.hovered
                    Material.foreground: toolTipForeground
                    Material.background: toolTipBackground
                }

                icon.source: "../images/info.svg"
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
