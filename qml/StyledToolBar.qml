import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ToolBar {
    id: toolBar

    background: Rectangle {
        id: rect
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
    property bool showAddCredentialBtn: true // TODO: should be shown when there is a yubikey and authenticated
    property bool showSettingsBtn: true
    property bool showTitleLbl: navigator.currentItem
                                && navigator.currentItem.title
    property alias searchField: searchField

    function shouldShowSearch() {
        return navigator.currentItem
                && navigator.currentItem.objectName == 'credentialsView'
                && entries.count > 0
    }

    RowLayout {
        spacing: 0
        anchors.leftMargin: 20
        anchors.fill: parent

        ToolButton {
            id: backBtn
            visible: showBackBtn
            onClicked: navigator.pop(StackView.Immediate)

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: false
            }

            Image {
                id: backIcon
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                Layout.maximumWidth: 150
                fillMode: Image.PreserveAspectFit
                source: "../images/back.svg"
                ColorOverlay {
                    source: backIcon
                    color: isDark() ? defaultLight : "#5f6368"
                    anchors.fill: backIcon
                }
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
            Layout.fillWidth: true
            color: isDark() ? defaultLight : "#5f6368"
        }

        ToolButton {
            id: searchBtn
            visible: showSearch
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

                Image {
                    id: searchIcon
                    x: 5
                    y: 6
                    height: 20
                    width: 20
                    fillMode: Image.PreserveAspectFit
                    source: "../images/search.svg"
                    ColorOverlay {
                        source: searchIcon
                        color: isDark() ? defaultLight : "#5f6368"
                        anchors.fill: searchIcon
                    }
                }
            }
        }
        RowLayout {
            id: credentialOptions
            spacing: 0
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            visible: !!(app.currentCredentialCard)
            ToolButton {
                id: deleteCredentialBtn
                visible: deleteCredentialBtn
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                onClicked: app.currentCredentialCard.deleteCard()

                ToolTip.text: "Delete credential from YubiKey"
                ToolTip.delay: 1000
                ToolTip.visible: hovered

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: false
                }

                Image {
                    id: deleteIcon
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    Layout.maximumWidth: 150
                    fillMode: Image.PreserveAspectFit
                    source: "../images/delete.svg"
                    ColorOverlay {
                        source: deleteIcon
                        color: isDark() ? defaultLight : "#5f6368"
                        anchors.fill: deleteIcon
                    }
                }
            }
        }

        RowLayout {
            spacing: 0
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

            ToolButton {
                id: addCredentialBtn
                visible: showAddCredentialBtn
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                onClicked: addNewCredentialMenu.open()
                ToolTip.text: "Add a new credential"
                ToolTip.delay: 1000
                ToolTip.visible: hovered

                //enabled: TODO: when visible?
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: false
                }

                Image {
                    id: addIcon
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    Layout.maximumWidth: 150
                    fillMode: Image.PreserveAspectFit
                    source: "../images/add.svg"
                    ColorOverlay {
                        source: addIcon
                        color: isDark() ? defaultLight : "#5f6368"
                        anchors.fill: addIcon
                    }
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
                ToolTip.text: "Configure Yubico Authenticator"
                ToolTip.delay: 1000
                ToolTip.visible: hovered

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: false
                }

                Image {
                    id: settingsIcon
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    Layout.maximumWidth: 150
                    fillMode: Image.PreserveAspectFit
                    source: "../images/cogwheel.svg"
                    ColorOverlay {
                        source: settingsIcon
                        color: isDark() ? defaultLight : "#5f6368"
                        anchors.fill: settingsIcon
                    }
                }
            }
        }
    }
}
