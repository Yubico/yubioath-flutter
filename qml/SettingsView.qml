import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {

    id: settingsPanel
    objectName: 'settingsView'
    contentWidth: app.width
    contentHeight: expandedHeight
    StackView.onActivating: load()

    property var expandedHeight: content.implicitHeight + dynamicMargin
    property bool isBusy
    property bool hasPin
    property bool pinBlocked
    property int pinRetries

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

    property string searchFieldPlaceholder: qsTr("Search settings")

    function load() {
        isBusy = true
        yubiKey.fidoHasPin(function (resp) {
            if (resp.success) {
                hasPin = resp.hasPin
                if (hasPin) {
                    yubiKey.fidoPinRetries(function (resp) {
                        if (resp.success) {
                            pinRetries = resp.retries
                        } else {
                            pinBlocked = (resp.error_id === 'PIN is blocked.')
                        }
                        isBusy = false
                    })
                } else {
                    pinBlocked = false
                    isBusy = false
                }
            } else {
                navigator.snackBarError(navigator.getErrorMessage(resp.error_id))
                views.home()
            }
        })
    }

    ColumnLayout {
        width: settingsPanel.contentWidth
        id: content
        spacing: 0

        StyledExpansionContainer {
            title: qsTr("General")

            SettingsPanelAppearance {}
            SettingsPanelCustomReader {}
            SettingsPanelSystemTray {}
            SettingsPanelClearPasswords {}
        }
        StyledExpansionContainer {
            title: qsTr("Bio")

            SettingsPanelFidoPin {}
            SettingsPanelBioList {}
            SettingsPanelBioAdd {}
            SettingsPanelBioDelete {}
            SettingsPanelFidoReset {}

        }
    }
}
