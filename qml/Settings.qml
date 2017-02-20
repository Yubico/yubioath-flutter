import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2

Dialog {
   title: qsTr("Settings")
   modality: Qt.ApplicationModal

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
                checked: true
                exclusiveGroup: mode
            }
            RadioButton {
                id: slot
                text: qsTr("YubiKey Slots")
                exclusiveGroup: mode
            }
            CheckBox {
                id: slot1
                enabled: mode.current == slot
                text: qsTr("Slot 1")
            }
            RowLayout{
                Label {
                    text: qsTr("Digits")
                    enabled: mode.current == slot && slot1.checked
                }
                ComboBox {
                    id: slot1digits
                    enabled: mode.current == slot && slot1.checked
                    model: [6, 8]
                }

            }
            CheckBox {
                id: slot2
                enabled: mode.current == slot
                text: qsTr("Slot 2")
            }
            RowLayout{
                Label {
                    text: qsTr("Digits")
                    enabled: mode.current == slot && slot2.checked
                }
                ComboBox {
                    id: slot2digits
                    enabled: mode.current == slot && slot2.checked
                    model: [6, 8]
                }

            }

        }

    }

}
