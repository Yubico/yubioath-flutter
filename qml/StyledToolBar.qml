import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ToolBar {
    id: toolBar

    background: Rectangle {
        color: isDark() ? defaultDark : defaultLight
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
    property bool showAddCredentialBtn: shouldShowAddCredential()
    property bool showSettingsBtn: shouldShowSettings()
    property bool showTitleLbl: !!navigator.currentItem
                                && !!navigator.currentItem.title

    property alias searchField: searchField

    function shouldShowSearch() {
        return !!(navigator.currentItem
                  && navigator.currentItem.objectName === 'credentialsView'
                  && entries.count > 0 && !settings.otpMode)
    }

    function shouldShowAddCredential() {
        return !!(yubiKey.currentDevice && yubiKey.currentDeviceValidated
                  && navigator.currentItem
                  && navigator.currentItem.objectName === 'credentialsView'
                  && !shouldShowCredentialOptions())
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
                    opacity: 0.8
                }

                onTextChanged: forceActiveFocus()

                function exitSearchMode(clearInput) {
                    text = clearInput ? "" : text
                    focus = false
                    Keys.forwardTo = navigator
                    navigator.forceActiveFocus()
                }

                KeyNavigation.tab: shouldShowCredentialOptions(
                                       ) ? copyCredentialBtn : addCredentialBtn

                Keys.onEscapePressed: exitSearchMode(true)
                Keys.onReturnPressed: exitSearchMode(false)
                Keys.onEnterPressed: exitSearchMode(false)
                Keys.onDownPressed: exitSearchMode(false)

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
                    Material.foreground: app.isDark(
                                             ) ? defaultDarkForeground : defaultLight
                    Material.background: app.isDark(
                                             ) ? defaultDarkOverlay : defaultLightForeground
                }

                icon.source: "../images/copy.svg"
                icon.color: isDark() ? defaultLight : "#5f6368"

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
                KeyNavigation.right: favouriteBtn
                KeyNavigation.tab: favouriteBtn

                ToolTip {
                    text: "Delete credential"
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
                id: favouriteBtn
                visible: shouldShowCredentialOptions()
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                onClicked: app.currentCredentialCard.toggleFavourite()
                Keys.onReturnPressed: app.currentCredentialCard.toggleFavourite(
                                          )
                Keys.onEnterPressed: app.currentCredentialCard.toggleFavourite()
                KeyNavigation.left: deleteCredentialBtn
                KeyNavigation.right: settingsBtn
                KeyNavigation.tab: settingsBtn

                ToolTip {
                    text: "Favourite credential"
                    delay: 1000
                    parent: favouriteBtn
                    visible: parent.hovered
                    Material.foreground: app.isDark(
                                             ) ? defaultDarkForeground : defaultLight
                    Material.background: app.isDark(
                                             ) ? defaultDarkOverlay : defaultLightForeground
                }

                icon.source: shouldShowCredentialOptions()
                             && app.currentCredentialCard.isFavourite(
                                 ) ? "../images/star.svg" : "../images/star_border.svg"
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
            }

            ToolButton {
                id: settingsBtn
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                visible: showSettingsBtn
                onClicked: navigator.goToSettings()

                Keys.onReturnPressed: navigator.goToSettings()
                Keys.onEnterPressed: navigator.goToSettings()

                KeyNavigation.left: shouldShowCredentialOptions(
                                        ) ? deleteCredentialBtn : addCredentialBtn
                KeyNavigation.right: navigator
                KeyNavigation.tab: navigator

                ToolTip {
                    text: "Settings"
                    delay: 1000
                    parent: settingsBtn
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
