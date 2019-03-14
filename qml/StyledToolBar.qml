import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ToolBar {
    id: toolBar

    property bool showSearch: true
    property bool showBackBtn: false
    property bool showAddCredentialBtn: true
    property bool showSettingsBtn: true

    RowLayout {
        id: row
        spacing: 0
        anchors.leftMargin: 20
        anchors.fill: parent

        ToolButton {
            id: backBtn
            visible: showBackBtn
            text: qsTr("‹")
        }

        TextField {
            id: searchField
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            visible: showSearch
            placeholderText: "Search..."
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            background.width: width
        }

        RowLayout {
            spacing: 0
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

            ToolButton {
                id: addCredentialBtn
                visible: showAddCredentialBtn
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
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
                anchors.right: parent.right
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                visible: showSettingsBtn
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
