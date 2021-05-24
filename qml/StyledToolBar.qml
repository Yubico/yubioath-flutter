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


    property string searchFieldPlaceholder: !!navigator.currentItem ? navigator.currentItem.searchFieldPlaceholder || "" : ""

    RowLayout {
        spacing: 0
        anchors.fill: parent
        visible: !navigator.isInLoading()
        Layout.alignment: Qt.AlignTop

        ToolButton {
            id: drawerBtn
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.leftMargin: 4
            visible: !navigator.isInLoading() && !navigator.isInFlickable()

            onClicked: drawer.toggle()
            Keys.onReturnPressed: drawer.toggle()
            Keys.onEnterPressed: drawer.toggle()

            KeyNavigation.left: navigator
            KeyNavigation.backtab: navigator
            KeyNavigation.right: searchField.visible ? searchField : closeBtn
            KeyNavigation.tab: searchField.visible ? searchField : closeBtn

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
            id: backBtn
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.leftMargin: 4
            visible: !navigator.isInLoading() && navigator.isInFlickable()

            onClicked: navigator.pop()
            Keys.onReturnPressed: navigator.pop()
            Keys.onEnterPressed: navigator.pop()

            KeyNavigation.left: navigator
            KeyNavigation.backtab: navigator
            KeyNavigation.right: searchField.visible ? searchField : closeBtn
            KeyNavigation.tab: searchField.visible ? searchField : closeBtn

            Accessible.role: Accessible.Button
            Accessible.name: "Back"
            Accessible.description: "Back button"

            icon.source: "../images/back.svg"
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
                selectedTextColor: fullContrast
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
                KeyNavigation.tab: addCredentialBtn
                KeyNavigation.right: addCredentialBtn
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
                id: addCredentialBtn
                visible: !!yubiKey.currentDevice
                         && yubiKey.currentDeviceEnabled("OATH")
                         && navigator.isInAuthenticator()

                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                onClicked: navigator.goToNewCredential()
                Keys.onReturnPressed: navigator.goToNewCredential()
                Keys.onEnterPressed: navigator.goToNewCredential()

                KeyNavigation.left: searchField
                KeyNavigation.backtab: searchField
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

                KeyNavigation.left: drawerBtn
                KeyNavigation.backtab: drawerBtn
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
