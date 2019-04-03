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
    }

    function getToolbarColor(isActive) {
        if (!isActive) {
            return "transparent"
        } else {
            if (isDark()) {
                return defaultDarkLighter
            } else {
                return defaultLightDarker
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
                    color: isDark() ? yubicoWhite : yubicoGrey
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
            color: isDark() ? yubicoWhite : yubicoGrey
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
                Material.accent: isDark() ? yubicoWhite : yubicoGrey
                selectByMouse: true
                selectedTextColor: isDark() ? defaultDark : defaultLight
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                placeholderText: isDark(
                                     ) ? "<font color='#f0f0f0'>Quick Find</font>" : "<font color='#939598'>Quick Find</font>"
                //                placeholderTextColor: "#f0f0f0"       // Qt5.12 requirement, hold for now?
                padding: 28
                width: parent.width
                horizontalAlignment: Qt.AlignLeft
                verticalAlignment: Qt.AlignVCenter
                color: isDark() ? yubicoWhite : yubicoGrey
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
                        color: isDark() ? yubicoWhite : yubicoGrey
                        anchors.fill: searchIcon
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
                        color: isDark() ? yubicoWhite : yubicoGrey
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
                        color: isDark() ? yubicoWhite : yubicoGrey
                        anchors.fill: settingsIcon
                    }
                }
            }
        }
    }
}
