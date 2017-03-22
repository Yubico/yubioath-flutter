import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2

DefaultDialog {
    title: qsTr("Settings")
    modality: Qt.ApplicationModal

    property var settings
    property alias slotMode: slotMode.checked
    property alias slot1: slot1.checked
    property alias slot2: slot2.checked
    property alias slot1digits: slot1digits.currentIndex
    property alias slot2digits: slot2digits.currentIndex
    ColumnLayout {
        anchors.fill: parent
        Label {
            text: qsTr("Authenticator Mode")
            font.bold: true
        }
        ColumnLayout {
            ExclusiveGroup {
                id: mode
            }
            RadioButton {
                focus: true
                id: ccid
                text: qsTr("CCID (Smart card)")
                checked: !settings.slotMode
                exclusiveGroup: mode
                KeyNavigation.tab: slotMode
                Keys.onEscapePressed: close()
            }
            RadioButton {
                id: slotMode
                checked: settings.slotMode
                text: qsTr("YubiKey Slots")
                exclusiveGroup: mode
                KeyNavigation.tab: slot1
                Keys.onEscapePressed: close()
            }
            CheckBox {
                id: slot1
                enabled: mode.current == slotMode
                checked: settings.slot1
                text: qsTr("Slot 1")
                KeyNavigation.tab: slot1digits
                Keys.onEscapePressed: close()
            }
            RowLayout {
                Label {
                    text: qsTr("Digits")
                    enabled: mode.current == slotMode && slot1.checked
                }
                ComboBox {
                    id: slot1digits
                    currentIndex: settings.slot1digits != null ? settings.slot1digits : 0
                    enabled: mode.current == slotMode && slot1.checked
                    model: [6, 8]
                    KeyNavigation.tab: slot2
                    Keys.onEscapePressed: close()
                }
            }
            CheckBox {
                id: slot2
                enabled: mode.current == slotMode
                checked: settings.slot2
                text: qsTr("Slot 2")
                KeyNavigation.tab: slot2digits
                Keys.onEscapePressed: close()
            }
            RowLayout {
                Label {
                    text: qsTr("Digits")
                    enabled: mode.current == slotMode && slot2.checked
                }
                ComboBox {
                    id: slot2digits
                    currentIndex: settings.slot2digits != null ? settings.slot2digits : 0
                    enabled: mode.current == slotMode && slot2.checked
                    model: [6, 8]
                    KeyNavigation.tab: saveSettingsBtn
                    Keys.onEscapePressed: close()
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom
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
            Button {
                id: cancelBtn
                text: qsTr("Cancel")
                onClicked: close()
                KeyNavigation.tab: ccid
                Keys.onEscapePressed: close()
            }
        }
    }

    function shouldAccept() {
        return ((mode.current == slotMode) && (slot1.checked || slot2.checked))
                || mode.current == ccid
    }
}
