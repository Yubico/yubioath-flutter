import QtGraphicalEffects 1.0
import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3

Flickable {
    id: settingsPanel

    property string title: qsTr("")

    objectName: "settingsView"
    contentWidth: app.width
    contentHeight: content.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    Keys.onEscapePressed: navigator.home()

    ColumnLayout {
        id: content

        anchors.fill: parent
        Layout.alignment: Qt.AlignTop
        spacing: 0

        StyledExpansionContainer {
            title: qsTr("Device")

            SettingsPanelCurrentDevice {
            }

        }

        StyledExpansionContainer {
            title: qsTr("Application")

            SettingsPanelAppearance {
            }

            SettingsPanelCustomReader {
            }

            SettingsPanelSystemTray {
            }

            SettingsPanelClearPasswords {
            }

        }

        StyledExpansionContainer {
            title: qsTr("Security Codes (OATH)")

            SettingsPanelPasswordMgmt {
            }

            SettingsPanelResetDevice {
            }

        }

    }

    ScrollBar.vertical: ScrollBar {
        width: 8
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        hoverEnabled: true
        z: 2
    }

}
