import QtGraphicalEffects 1.0
import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3

StyledExpansionPanel {
    label: Qt.platform.os === "osx" ? "Menu bar" : "System tray"
    description: qsTr("Configure where and how the application is visible.")

    ColumnLayout {
        CheckBox {
            id: sysTrayCheckbox

            checked: settings.closeToTray
            text: Qt.platform.os === "osx" ? qsTr("Show in menu bar") : qsTr("Show in system tray")
            padding: 0
            indicator.width: 16
            indicator.height: 16
            onCheckStateChanged: {
                if (!checked)
                    hideOnLaunchCheckbox.checked = false;

                settings.closeToTray = checked;
            }
        }

        CheckBox {
            id: hideOnLaunchCheckbox

            enabled: sysTrayCheckbox.checked
            checked: settings.hideOnLaunch
            text: qsTr("Hide on launch")
            padding: 0
            indicator.width: 16
            indicator.height: 16
            onCheckStateChanged: settings.hideOnLaunch = checked
        }

    }

}
