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
                id: ccid
                text: qsTr("CCID (Smart card)")
                checked: !settings.slotMode
                exclusiveGroup: mode
            }
            RadioButton {
                id: slotMode
                checked: settings.slotMode
                text: qsTr("YubiKey Slots")
                exclusiveGroup: mode
            }
            CheckBox {
                id: slot1
                enabled: mode.current == slotMode
                checked: settings.slot1
                text: qsTr("Slot 1")
            }
            RowLayout{
                Label {
                    text: qsTr("Digits")
                    enabled: mode.current == slotMode && slot1.checked
                }
                ComboBox {
                    id: slot1digits
                    currentIndex: settings.slot1digits
                    enabled: mode.current == slotMode && slot1.checked
                    model: [6, 8]
                }

            }
            CheckBox {
                id: slot2
                enabled: mode.current == slotMode
                checked: settings.slot2
                text: qsTr("Slot 2")
            }
            RowLayout{
                Label {
                    text: qsTr("Digits")
                    enabled: mode.current == slotMode && slot2.checked
                }
                ComboBox {
                    id: slot2digits
                    currentIndex: settings.slot2digits
                    enabled: mode.current == slotMode && slot2.checked
                    model: [6, 8]
                }

            }

        }

        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom
            Button {
                text: qsTr("Save Settings")
                enabled: shouldAccept()
                Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                onClicked: {close(); accepted()}
            }
            Button {
                text: qsTr("Cancel")
                onClicked: close()
            }
        }

    }

    function shouldAccept() {
        return ((mode.current == slotMode) && (slot1.checked || slot2.checked)) || mode.current == ccid
    }

}
