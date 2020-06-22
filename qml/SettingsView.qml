import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {

    id: settingsPanel
    objectName: 'settingsView'
    contentWidth: app.width
    contentHeight: content.implicitHeight

    ScrollBar.vertical: ScrollBar {
        width: 8
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        hoverEnabled: true
        z: 2
    }
    boundsBehavior: Flickable.StopAtBounds

    Keys.onEscapePressed: navigator.home()

    property string title: qsTr("")

    ColumnLayout {
        id: content
        anchors.fill: parent
        Layout.alignment: Qt.AlignTop
        spacing: 0

        StyledExpansionContainer {
            title: qsTr("Device")

            SettingsPanelCurrentDevice {}
        }

        StyledExpansionContainer {

            SettingsPanelInterfaces {}
        }

        StyledExpansionContainer {
            title: qsTr("Application")

            SettingsPanelAppearance {}
            SettingsPanelCustomReader {}
            SettingsPanelSystemTray {}
            SettingsPanelClearPasswords {}
        }

        StyledExpansionContainer {
            title: qsTr("Security Codes (OATH)")

            SettingsPanelPasswordMgmt {}
            SettingsPanelResetDevice {}
        }



    }
}
