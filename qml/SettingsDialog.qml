import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2

DefaultDialog {
    title: qsTr("Settings")
    modality: Qt.ApplicationModal

    property var settings
    property bool slotMode: authenticatorMode.currentIndex == 1
    property alias slot1: slot1.checked
    property alias slot2: slot2.checked
    property alias slot1digits: slot1digits.currentIndex
    property alias slot2digits: slot2digits.currentIndex
    property alias closeToTray: closeToTray.checked

    ColumnLayout {
        anchors.fill: parent

        GridLayout {
            columns: 2
            Label {
                text: qsTr("Authenticator Mode")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.fillWidth: false
            }
            ComboBox {
                id: authenticatorMode
                Layout.fillWidth: true
                focus: true
                currentIndex: settings.slotMode ? 1 : 0
                model: [qsTr('CCID (Smart card)'), qsTr('YubiKey Slots')]
                KeyNavigation.tab: slot1
                Keys.onEscapePressed: close()
            }
            Label {
                text: qsTr("Read from Slot 1")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.fillWidth: false
                enabled: slotMode
            }
            GridLayout {
                CheckBox {
                    id: slot1
                    checked: settings.slot1
                    enabled: slotMode
                    KeyNavigation.tab: slot1digits
                    Keys.onEscapePressed: close()
                }
                Label {
                    text: qsTr("Digits")
                    enabled: slot1.checked
                }
                ComboBox {
                    id: slot1digits
                    model: [6, 7, 8]
                    enabled: slot1.checked && slotMode
                    currentIndex: settings.slot1digits != null ? settings.slot1digits : 0
                    KeyNavigation.tab: slot2
                    Keys.onEscapePressed: close()
                }
            }
            Label {
                text: qsTr("Read from Slot 2")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.fillWidth: false
                enabled: slotMode
            }
            GridLayout {
                CheckBox {
                    id: slot2
                    enabled: slotMode
                    checked: settings.slot2
                    KeyNavigation.tab: slot2digits
                    Keys.onEscapePressed: close()
                }
                Label {
                    text: qsTr("Digits")
                    enabled: slot2.checked
                }
                ComboBox {
                    id: slot2digits
                    currentIndex: settings.slot2digits != null ? settings.slot2digits : 0
                    model: [6, 7, 8]
                    enabled: slot2.checked && slotMode
                    KeyNavigation.tab: closeToTray
                    Keys.onEscapePressed: close()
                }
            }
            Label {
                text: qsTr("Show in system tray")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.fillWidth: false
            }
            CheckBox {
                id: closeToTray
                checked: settings.closeToTray
                KeyNavigation.tab: saveSettingsBtn
                Keys.onEscapePressed: close()
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom

            Button {
                id: cancelBtn
                text: qsTr("Cancel")
                onClicked: close()
                KeyNavigation.tab: authenticatorMode
                Keys.onEscapePressed: close()
            }
            Button {
                id: saveSettingsBtn
                text: qsTr("Save Settings")
                enabled: shouldAccept()
                Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                onClicked: {
                    close()
                    accepted()
                }
                KeyNavigation.tab: cancelBtn
                Keys.onEscapePressed: close()
            }
        }
    }

    function shouldAccept() {
        return ((slotMode) && (slot1.checked || slot2.checked)) || !slotMode
    }
}
