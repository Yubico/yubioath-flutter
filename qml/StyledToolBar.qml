import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ToolBar {
    id: toolBar

    property bool showSearch: stackView.currentItem.objectName == 'credentialsView'
    property bool showBackBtn: stackView.depth > 1
    property bool showAddCredentialBtn: true // TODO: should be shown when there is a yubikey and authenticated
    property bool showSettingsBtn: true
    property bool showTitleLbl: stackView.currentItem.title.length > 1

    RowLayout {
        spacing: 0
        anchors.leftMargin: 20
        anchors.fill: parent

        ToolButton {
            id: backBtn
            visible: showBackBtn
            onClicked: stackView.pop()

            Image {
                id: backIcon
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                Layout.maximumWidth: 150
                fillMode: Image.PreserveAspectFit
                source: "../images/back.svg"
                ColorOverlay {
                    source: backIcon
                    color: yubicoWhite
                    anchors.fill: backIcon
                }
            }
        }

        Label {
            id: titleLbl
            visible: showTitleLbl
            text: stackView.currentItem.title
            font.pixelSize: 16
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            Layout.fillWidth: true
            color: yubicoWhite
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
                color: searchBtn.hovered ? "#a6d14c" : "transparent"
                height: 30
                radius: 4
            }

            TextField {
                id: searchField
                Material.accent: yubicoWhite
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                visible: showSearch
                placeholderText: "Quick Find"
//                placeholderTextColor: "#f0f0f0"       // Qt5.12 requirement, hold for now?
                padding: 28
                width: searchBtn.width
                horizontalAlignment: Qt.AlignLeft
                verticalAlignment: Qt.AlignVCenter
                color: yubicoWhite
                background: Rectangle {
                    color: searchField.focus ? "#a6d14c" : "transparent"
                    height: 30
                    radius: 4
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
                        color: yubicoWhite
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
                onClicked: app.goToCredentials()

                ToolTip.text: "Add a new credential"
                ToolTip.delay: 1000
                ToolTip.visible: hovered

                Image {
                    id: addIcon
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    Layout.maximumWidth: 150
                    fillMode: Image.PreserveAspectFit
                    source: "../images/add.svg"
                    ColorOverlay {
                        source: addIcon
                        color: yubicoWhite
                        anchors.fill: addIcon
                    }
                }
            }

            ToolButton {
                id: settingsButton
//                anchors.right: parent.right
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                visible: showSettingsBtn
                onClicked: app.goToSettings()

                ToolTip.text: "Configure Yubico Authenticator"
                ToolTip.delay: 1000
                ToolTip.visible: hovered

                Image {
                    id: settingsIcon
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    Layout.maximumWidth: 150
                    fillMode: Image.PreserveAspectFit
                    source: "../images/cogwheel.svg"
                    ColorOverlay {
                        source: settingsIcon
                        color: yubicoWhite
                        anchors.fill: settingsIcon
                    }
                }
            }
        }
    }
}
