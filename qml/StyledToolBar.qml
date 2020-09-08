import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0
import Qt.labs.platform 1.1 as PopUpMenu

ToolBar {
    id: toolBar

    background: Rectangle {
        color: defaultBackground
        opacity: 0.7
    }

    width: app.width

    function getToolbarColor(isActive) {
        if (!isActive) {
            return 0
        } else {
            return 0.05
        }
    }

    property alias drawerBtn: drawerBtn
    property alias addCredentialBtn: addCredentialBtn
    property alias searchField: searchField
    property alias requireTouchBtn: requireTouchBtn
    property alias advancedSettingsBtn: advancedSettingsBtn

    property string searchFieldPlaceholder: !!navigator.currentItem ? navigator.currentItem.searchFieldPlaceholder || "" : ""

    function shouldShowCredentialOptions() {
        return !!navigator && navigator.isInAuthenticator() && navigator.hasSelectedOathCredential()
    }

    RowLayout {
        spacing: 0
        anchors.fill: parent
        visible: !navigator.isInLoading()
        Layout.alignment: Qt.AlignTop

        ToolButton {
            id: drawerBtn
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.leftMargin: 4
            visible: !navigator.isInLoading()

            onClicked: drawer.toggle()
            Keys.onReturnPressed: drawer.toggle()
            Keys.onEnterPressed: drawer.toggle()

            KeyNavigation.left: navigator
            KeyNavigation.backtab: navigator
            KeyNavigation.right: searchField.visible ? searchField : (requireTouchBtn.visible ? requireTouchBtn : advancedSettingsBtn)
            KeyNavigation.tab: searchField.visible ? searchField : (requireTouchBtn.visible ? requireTouchBtn : advancedSettingsBtn)

            Accessible.role: Accessible.Button
            Accessible.name: "Menu"
            Accessible.description: "Menu button"

            icon.source: "../images/menu.svg"
            icon.color: primaryColor
            opacity: hovered ? fullEmphasis : lowEmphasis

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: false
            }
        }

        ToolButton {
            id: searchBtn
            visible: searchField.placeholderText != ""
            Layout.minimumHeight: 30
            Layout.maximumHeight: 30
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            background: Rectangle {
                color: primaryColor
                opacity: getToolbarColor(searchBtn.hovered)
                height: 30
                radius: 4
            }

            TextField {
                id: searchField
                visible: parent.visible
                selectByMouse: true
                selectedTextColor: defaultBackground
                Layout.fillWidth: true
                Layout.fillHeight: true
                placeholderText: searchFieldPlaceholder
                placeholderTextColor: isDark() ? "#B7B7B7" : "#767676"
                leftPadding: 28
                rightPadding: 8
                width: parent.width
                horizontalAlignment: Qt.AlignLeft
                verticalAlignment: Qt.AlignVCenter
                color: primaryColor
                opacity: hovered || activeFocus ? fullEmphasis : lowEmphasis
                background: Rectangle {
                    color: primaryColor
                    height: 30
                    radius: 4
                    opacity: getToolbarColor(searchField.focus)
                }

                Accessible.role: Accessible.EditableText
                Accessible.searchEdit: true
                onTextChanged: forceActiveFocus()
                onVisibleChanged: {
                    if (!visible) {
                        exitSearchMode(true)
                    }
                }
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

                PopUpMenu.Menu {
                    id: contextMenu

                    PopUpMenu.MenuItem {
                        text: qsTr("Cut")
                        onTriggered: {
                            searchField.cut()
                        }
                    }
                    PopUpMenu.MenuItem {
                        text: qsTr("Copy")
                        onTriggered: {
                            searchField.copy()
                        }
                    }
                    PopUpMenu.MenuItem {
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
                    navigator.forceActiveFocus()
                }

                KeyNavigation.backtab: drawerBtn
                KeyNavigation.left: drawerBtn
                KeyNavigation.tab: shouldShowCredentialOptions(
                                       ) ? copyCredentialBtn : addCredentialBtn
                KeyNavigation.right: shouldShowCredentialOptions(
                                       ) ? copyCredentialBtn : addCredentialBtn
                Keys.onEscapePressed: exitSearchMode(true)
                Keys.onDownPressed: exitSearchMode(false)
                Keys.onReturnPressed: {
                    if (navigator.hasSelectedOathCredential()) {
                        navigator.oathCopySelectedCredential()
                    }
                }
                Keys.onEnterPressed: {
                    if (navigator.hasSelectedOathCredential()) {
                        navigator.oathCopySelectedCredential()
                    }
                }

                StyledImage {
                    id: searchIcon
                    x: 5
                    y: 6
                    iconHeight: 20
                    iconWidth: 20
                    source: "../images/search.svg"
                    color: primaryColor
                    opacity: searchField.hovered || searchField.activeFocus ? fullEmphasis : lowEmphasis

                }
            }
        }

        RowLayout {
            spacing: 0
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

            ToolButton {
                id: requireTouchBtn
                property bool isSelected
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                visible: navigator.isInNewOathCredential()

                onClicked: isSelected = !isSelected
                Keys.onReturnPressed: navigator.oathCopySelectedCredential()
                Keys.onEnterPressed: navigator.oathCopySelectedCredential()

                KeyNavigation.left: drawerBtn
                KeyNavigation.backtab: drawerBtn
                KeyNavigation.right: advancedSettingsBtn
                KeyNavigation.tab: advancedSettingsBtn

                Accessible.role: Accessible.Button
                Accessible.name: "RequireTouch"
                Accessible.description: "Toggle require touch"

                ToolTip {
                    text: qsTr("Require touch to display code is %1").arg(parent.isSelected ? "ON" : "OFF")
                    delay: 1000
                    visible: parent.hovered
                    Material.foreground: toolTipForeground
                    Material.background: toolTipBackground
                }

                icon.source: "../images/attach.svg"
                icon.color: isSelected ? yubicoGreen : primaryColor
                opacity: hovered || isSelected ? fullEmphasis : lowEmphasis

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: false
                }
            }

            ToolButton {
                id: advancedSettingsBtn
                property bool isSelected
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                visible: navigator.isInNewOathCredential()

                onClicked: isSelected = !isSelected
                Keys.onReturnPressed: navigator.oathCopySelectedCredential()
                Keys.onEnterPressed: navigator.oathCopySelectedCredential()

                KeyNavigation.left: requireTouchBtn.visible ? requireTouchBtn : drawerBtn
                KeyNavigation.backtab: requireTouchBtn.visible ? requireTouchBtn : drawerBtn
                KeyNavigation.right: closeBtn
                KeyNavigation.tab: closeBtn

                Accessible.role: Accessible.Button
                Accessible.name: "Advanced"
                Accessible.description: "Toggle advanced settings"

/*                ToolTip {
                    text: qsTr("%1 advanced settings").arg(parent.isSelected ? "Hide" : "Show")
                    delay: 1000
                    visible: parent.hovered
                    Material.foreground: toolTipForeground
                    Material.background: toolTipBackground
                }
*/
                /*
                ToolTip {
                    id: control
                    text: qsTr("Use this button to scan\nscreen for QR code")
                    visible: true

                    contentItem: Text {
                        text: control.text
                        font: control.font
                        color: defaultBackground
                    }

                    background: Rectangle {
                        color: "yellow"
                        border.color: "yellow"
                    }
                }
*/



                icon.source: "../images/qr-scanner.svg"
                icon.color: isSelected ? yubicoGreen : primaryColor
                opacity: hovered || isSelected ? fullEmphasis : lowEmphasis

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: false
                }
            }

            ToolButton {
                id: copyCredentialBtn
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                visible: shouldShowCredentialOptions()

                onClicked: navigator.oathCopySelectedCredential()
                Keys.onReturnPressed: navigator.oathCopySelectedCredential()
                Keys.onEnterPressed: navigator.oathCopySelectedCredential()

                KeyNavigation.left: searchField
                KeyNavigation.backtab: searchField
                KeyNavigation.right: deleteCredentialBtn
                KeyNavigation.tab: deleteCredentialBtn

                Accessible.role: Accessible.Button
                Accessible.name: "Copy"
                Accessible.description: "Copy to clipboard"

                ToolTip {
                    text: qsTr("Copy code to clipboard (%1)").arg(shortcutCopy.nativeText)
                    delay: 1000
                    parent: copyCredentialBtn
                    visible: parent.hovered
                    Material.foreground: toolTipForeground
                    Material.background: toolTipBackground
                }

                icon.source: "../images/copy.svg"
                icon.color: primaryColor
                opacity: hovered ? fullEmphasis : lowEmphasis

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: false
                }
            }

            ToolButton {
                id: deleteCredentialBtn
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                visible: shouldShowCredentialOptions()

                onClicked: navigator.oathDeleteSelectedCredential()
                Keys.onReturnPressed: navigator.oathDeleteSelectedCredential()
                Keys.onEnterPressed: navigator.oathDeleteSelectedCredential()

                KeyNavigation.left: copyCredentialBtn
                KeyNavigation.right: addCredentialBtn
                KeyNavigation.tab: addCredentialBtn

                Accessible.role: Accessible.Button
                Accessible.name: "Delete"
                Accessible.description: "Delete account"

                ToolTip {
                    text: qsTr("Delete account (%1)").arg(shortcutDelete.nativeText)
                    delay: 1000
                    parent: deleteCredentialBtn
                    visible: parent.hovered
                    Material.foreground: toolTipForeground
                    Material.background: toolTipBackground
                }

                icon.source: "../images/delete.svg"
                icon.color: primaryColor
                opacity: hovered ? fullEmphasis : lowEmphasis

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: false
                }
            }

            ToolButton {
                id: addCredentialBtn
                visible: !!yubiKey.currentDevice
                         && yubiKey.currentDeviceEnabled("OATH")
                         && navigator.isInAuthenticator()

                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                onClicked: navigator.goToNewCredential()
                Keys.onReturnPressed: navigator.goToNewCredential()
                Keys.onEnterPressed: navigator.goToNewCredential()

                KeyNavigation.left: !!navigator && navigator.isInAuthenticator() && navigator.hasSelectedOathCredential() ? deleteCredentialBtn : searchField
                KeyNavigation.backtab: !!navigator && navigator.isInAuthenticator() && navigator.hasSelectedOathCredential() ? deleteCredentialBtn : searchField
                KeyNavigation.right: navigator
                KeyNavigation.tab: navigator

                Accessible.role: Accessible.Button
                Accessible.name: qsTr("Add")
                Accessible.description: qsTr("Add account")

                ToolTip {
                    text: qsTr("Add new account (%1)").arg(shortcutAddAccount.nativeText)
                    delay: 1000
                    parent: addCredentialBtn
                    visible: parent.hovered
                    Material.foreground: toolTipForeground
                    Material.background: toolTipBackground
                }

                icon.source: "../images/add.svg"
                icon.color: primaryColor
                opacity: hovered ? fullEmphasis : lowEmphasis

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: false
                }
            }

            ToolButton {
                id: closeBtn
                activeFocusOnTab: true
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                visible: navigator.isInNewOathCredential()
                onClicked: navigator.goToAuthenticator()
                icon.source: "../images/clear.svg"
                icon.color: primaryColor
                opacity: hovered ? fullEmphasis : lowEmphasis

                Keys.onReturnPressed: navigator.goToAuthenticator()
                Keys.onEnterPressed: navigator.goToAuthenticator()

                KeyNavigation.left: advancedSettingsBtn.visible ? advancedSettingsBtn : drawerBtn
                KeyNavigation.backtab: advancedSettingsBtn.visible ? advancedSettingsBtn : drawerBtn
                KeyNavigation.right: navigator
                KeyNavigation.tab: navigator

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: false
                }
            }
        }
    }
}
