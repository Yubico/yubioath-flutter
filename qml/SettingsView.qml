import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {

    id: settingsPanel
    objectName: 'settingsView'
    contentWidth: app.width-32
    contentHeight: content.implicitHeight
    leftMargin: 16
    rightMargin: 16

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

    RowLayout {
        width: settingsPanel.contentWidth
        ColumnLayout {
            id: content
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            spacing: 0

            StyledExpansionContainer {
                title: qsTr("Application")

                SettingsPanelAppearance {}
                SettingsPanelCustomReader {}
                SettingsPanelSystemTray {}
                SettingsPanelClearPasswords {}
            }

            StyledExpansionContainer {
                title: qsTr("Authenticator app (OATH)")

                SettingsPanelPasswordMgmt {}
                SettingsPanelResetDevice {}
            }

        }
    }
}
