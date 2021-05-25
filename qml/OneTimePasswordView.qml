import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {

    id: settingsPanel
    objectName: 'yubiKeyOneTimePasswordView'
    contentWidth: app.width
    contentHeight: expandedHeight

    property var expandedHeight: content.implicitHeight + dynamicMargin

    onExpandedHeightChanged: {
        if (expandedHeight > app.height - toolBar.height) {
             scrollBar.active = true
         }
    }

    ScrollBar.vertical: ScrollBar {
        id: scrollBar
        width: 8
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        hoverEnabled: true
        z: 2
    }
    boundsBehavior: Flickable.StopAtBounds

    property string searchFieldPlaceholder: qsTr("Search configuration")

    ColumnLayout {
        width: settingsPanel.contentWidth
        id: content
        spacing: 0

        StyledExpansionContainer {
            title: qsTr("One-Time Password (OTP)")

            SettingsPanelOtp {
                id: otp0
                slot: 0 }
            SettingsPanelOtp {
                id: otp1
                slot: 1 }
            SettingsPanelOtpSwap {}
        }
    }
}
