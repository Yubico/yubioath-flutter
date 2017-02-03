import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2

Dialog {
    id: addCredential
    title: qsTr("Add credential")
    standardButtons: StandardButton.Save | StandardButton.Cancel

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
                id: nameInput
                Layout.fillHeight: false
                Layout.fillWidth: true
            }

            Label {
                text: qsTr("Secret key (base32)")
            }
            TextField {
                id: secretKeyInput
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
                    }
                    RadioButton {
                        text: qsTr("Counter based (HOTP)")
                        exclusiveGroup: oathType
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
                        exclusiveGroup: digits
                    }
                    RadioButton {
                        text: qsTr("8")
                        checked: true
                        exclusiveGroup: digits
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
                    }
                    RadioButton {
                        text: qsTr("SHA-256")
                        checked: true
                        exclusiveGroup: algorithm
                    }
                }
            }
        }
    }
}
