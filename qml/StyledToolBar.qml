import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ToolBar {
    id: toolBar

    background: Rectangle {
        color: isDark() ? defaultDark : defaultLight
        opacity: 0.9
        anchors {
            top: parent.top
            topMargin: -1
            left: parent.left
            leftMargin: -1
            right: parent.right
            rightMargin: -1
            bottom: parent.bottom
            bottomMargin: 0
        }
    }
    layer.enabled: true
    layer.effect: DropShadow {
        radius: 4
        samples: radius * 2
        verticalOffset: 3
        source: toolBar
        color: isDark() ? "#282828" : "#d3d3d3"
        transparentBorder: true
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
    property bool showAddCredentialBtn: shouldShowAddCredential()
    property bool showSettingsBtn: shouldShowSettings()
    property bool showTitleLbl: navigator.currentItem
                                && navigator.currentItem.title

    property alias searchField: searchField

    function shouldShowSearch() {
        return !!(navigator.currentItem
                  && navigator.currentItem.objectName === 'credentialsView'
                  && entries.count > 0 && !settings.otpMode)
    }

    function shouldShowAddCredential() {
        return !!(yubiKey.currentDevice && !yubiKey.locked
                  && navigator.currentItem
                  && navigator.currentItem.objectName === 'credentialsView')
    }

    function shouldShowSettings() {
        return !!(navigator.currentItem
                  && navigator.currentItem.objectName !== 'settingsView')
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
            onClicked: navigator.pop(StackView.Immediate)
            icon.source: "../images/back.svg"
            icon.color: isDark() ? defaultLight : "#5f6368"
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
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            rightPadding: showAddCredentialBtn || showSettingsBtn ? 0 : 40
            Layout.fillWidth: true
            color: isDark() ? defaultLight : "#5f6368"
        }

        ToolButton {
            id: searchBtn
            visible: showSearch
            Layout.leftMargin: 8
            Layout.minimumWidth: 200
            Layout.maximumWidth: 500
            Layout.minimumHeight: 30
            Layout.maximumHeight: 30
            Layout.fillWidth: true
            background: Rectangle {
                color: getToolbarColor(searchBtn.hovered)
                height: 30
                radius: 4
            }

            TextField {

                id: searchField
                visible: showSearch
                selectByMouse: true
                Material.accent: isDark() ? defaultLight : "#5f6368"
                selectedTextColor: isDark() ? defaultDark : defaultLight
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                placeholderText: "Quick Find"
                placeholderTextColor: isDark() ? defaultLight : yubicoGrey
                padding: 28
                width: parent.width
                horizontalAlignment: Qt.AlignLeft
                verticalAlignment: Qt.AlignVCenter
                color: isDark() ? defaultLight : "#5f6368"
                background: Rectangle {
                    color: getToolbarColor(searchField.focus)
                    height: 30
                    radius: 4
                }

                onTextChanged: forceActiveFocus()

                Keys.onEscapePressed: {
                    text = ""
                    focus = false
                    navigator.forceActiveFocus()
                }
                Keys.onDownPressed: {
                    focus = false
                    forwardTo: navigator
                    navigator.forceActiveFocus()
                }
                Keys.onReturnPressed: {
                    focus = false
                    forwardTo: navigator
                    navigator.forceActiveFocus()
                }

                StyledImage {
                    id: searchIcon
                    x: 5
                    y: 6
                    iconHeight: 20
                    iconWidth: 20
                    source: "../images/search.svg"
                    color: isDark() ? defaultLight : "#5f6368"
                }
            }
        }

        RowLayout {
            spacing: 0
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

            ToolButton {
                id: deleteCredentialBtn
                visible: shouldShowCredentialOptions()
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                onClicked: app.currentCredentialCard.deleteCard()

                ToolTip {
                    text: "Delete credential from YubiKey"
                    delay: 1000
                    parent: deleteCredentialBtn
                    visible: parent.hovered
                    Material.foreground: app.isDark(
                                             ) ? defaultDarkForeground : defaultLight
                    Material.background: app.isDark(
                                             ) ? defaultDarkOverlay : defaultLightForeground
                }

                icon.source: "../images/delete.svg"
                icon.color: isDark() ? defaultLight : "#5f6368"

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: false
                }
            }

            ToolButton {
                id: addCredentialBtn
                visible: showAddCredentialBtn
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                onClicked: addNewCredentialMenu.open()
                ToolTip {
                    text: "Add a new credential"
                    delay: 1000
                    parent: addCredentialBtn
                    visible: parent.hovered
                    Material.foreground: app.isDark(
                                             ) ? defaultDarkForeground : defaultLight
                    Material.background: app.isDark(
                                             ) ? defaultDarkOverlay : defaultLightForeground
                }

                icon.source: "../images/add.svg"
                icon.color: isDark() ? defaultLight : "#5f6368"

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: false
                }

                Menu {
                    id: addNewCredentialMenu
                    y: addCredentialBtn.height

                    MenuItem {
                        text: "Scan QR code"
                        onClicked: yubiKey.scanQr()
                    }

                    MenuItem {
                        text: "Manual entry"
                        onClicked: navigator.goToNewCredentialManual()
                    }
                }
            }

            ToolButton {
                id: settingsButton
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                visible: showSettingsBtn
                onClicked: navigator.goToSettings()
                ToolTip {
                    text: "Settings"
                    delay: 1000
                    parent: settingsButton
                    visible: parent.hovered
                    Material.foreground: app.isDark(
                                             ) ? defaultDarkForeground : defaultLight
                    Material.background: app.isDark(
                                             ) ? defaultDarkOverlay : defaultLightForeground
                }

                icon.source: "../images/cogwheel.svg"
                icon.color: isDark() ? defaultLight : "#5f6368"

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: false
                }
            }
        }
    }
}
