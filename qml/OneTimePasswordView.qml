import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {

    id: settingsPanel
    objectName: 'oneTimePasswordFlickable'
    contentWidth: app.width
    contentHeight: content.height + dynamicMargin

    onContentHeightChanged: {
        if (contentHeight > app.height - toolBar.height) {
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

    property string searchFieldPlaceholder: ""

    property bool slotConfigured

    function isSlotConfigured(slot) {
        yubiKey.slotsStatus(function (resp) {
            if (resp.success) {
                slotConfigured = resp.status[slot]
            } else {
                if (resp.error_id === 'timeout') {
                    navigator.snackBarError(qsTr("Failed to load OTP application"))
                } else {
                    navigator.snackBarError(
                                navigator.getErrorMessage(
                                    resp.error_id))
                }
                navigator.home()
            }
        })
        return slotConfigured
    }

    ColumnLayout {
        width: settingsPanel.contentWidth
        id: content
        spacing: 0

        StyledExpansionContainer {
            title: qsTr("One-Time Password (OTP)")

            StyledExpansionPanel {
                label: qsTr("Short touch (slot 1)")
                description: isSlotConfigured(0) ? qsTr("Slot is programmed") : qsTr("Slot is empty")
                enabled: !!yubiKey.currentDevice && yubiKey.currentDeviceSupported("OTP")
                toolButtonIcon: !enabled && yubiKey.currentDeviceSupported("OTP") ? "../images/warning.svg" : ""
                isFlickable: true
                isEnabled: enabled
                expandButton.onClicked: navigator.goToOneTimePasswordSlot(0)
            }
            StyledExpansionPanel {
                label: qsTr("Long touch (slot 2)")
                description: isSlotConfigured(1) ? qsTr("Slot is programmed") : qsTr("Slot is empty")
                enabled: !!yubiKey.currentDevice && yubiKey.currentDeviceSupported("OTP")
                toolButtonIcon: !enabled && yubiKey.currentDeviceSupported("OTP") ? "../images/warning.svg" : ""
                isFlickable: true
                isEnabled: enabled
                expandButton.onClicked: navigator.goToOneTimePasswordSlot(1)
            }
            SettingsPanelOtpSwap {}
        }
    }
}
