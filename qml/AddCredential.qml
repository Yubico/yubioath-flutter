import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2

Dialog {
    title: qsTr("Add credential")
    property var device
    standardButtons: StandardButton.Save | StandardButton.Cancel
    onAccepted: addCredential()

    ColumnLayout {
        GridLayout {
            columns: 2
            Button {
                Layout.columnSpan: 2
                text: qsTr("Scan a QR code")
                Layout.fillWidth: true
            }
            Label {
                text: qsTr("Name")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.fillWidth: false
            }
            TextField {
                id: name
                Layout.fillHeight: false
                Layout.fillWidth: true
            }

            Label {
                text: qsTr("Secret key (base32)")
            }
            TextField {
                id: key
                Layout.fillWidth: true
            }
        }
        GroupBox {
            title: qsTr("Credential type")
            ColumnLayout {
                RowLayout {
                    Label {
                        text: "OATH Type"
                    }
                    ExclusiveGroup {
                        id: oathType
                    }
                    RadioButton {
                        text: qsTr("Time based (TOTP)")
                        checked: true
                        exclusiveGroup: oathType
                        property string name: "totp"
                    }
                    RadioButton {
                        text: qsTr("Counter based (HOTP)")
                        exclusiveGroup: oathType
                        property string name: "hotp"
                    }
                }
                RowLayout {
                    Label {
                        text: "Number of digits"
                    }
                    ExclusiveGroup {
                        id: digits
                    }
                    RadioButton {
                        text: qsTr("6")
                        checked: true
                        exclusiveGroup: digits
                        property int digits: 6
                    }
                    RadioButton {
                        text: qsTr("8")
                        exclusiveGroup: digits
                        property int digits: 8
                    }
                }
                RowLayout {
                    Label {
                        text: "Algorithm"
                    }
                    ExclusiveGroup {
                        id: algorithm
                    }
                    RadioButton {
                        text: qsTr("SHA-1")
                        exclusiveGroup: algorithm
                        property string name: "SHA1"
                    }
                    RadioButton {
                        text: qsTr("SHA-256")
                        checked: true
                        exclusiveGroup: algorithm
                        property string name: "SHA256"
                    }
                }
                RowLayout {

                    CheckBox {
                        id: touch
                        text: "Require touch"
                        enabled: parseInt(device.version.split('.').join(
                                              '')) >= 426
                    }
                }
            }
        }
    }

    function addCredential() {
        device.addCredential(name.text, key.text, oathType.current.name,
                             digits.current.digits, algorithm.current.name,
                             touch.checked)
        device.refreshCredentials()
    }
}
