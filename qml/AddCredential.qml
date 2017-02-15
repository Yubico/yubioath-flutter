import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2

Dialog {
    title: qsTr("Add credential")
    standardButtons: StandardButton.Save | StandardButton.Cancel
    modality: Qt.ApplicationModal
    onAccepted: { addCredential(); clear(); }
    onRejected: clear()

    ColumnLayout {
        GridLayout {
            columns: 2
            Button {
                Layout.columnSpan: 2
                text: qsTr("Scan a QR code")
                Layout.fillWidth: true
                onClicked: device.parseQr(ScreenShot.capture(), updateForm);
            }
            Label {
                text: qsTr("Name")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.fillWidth: false
            }
            TextField {
                id: name
                Layout.fillWidth: true
            }

            Label {
                text: qsTr("Secret key (base32)")
            }
            TextField {
                id: key
                Layout.fillWidth: true
                validator: RegExpValidator {
                    regExp: /[ 2-7a-zA-Z]+=*/
                }
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
                        id: totp
                        text: qsTr("Time based (TOTP)")
                        checked: true
                        exclusiveGroup: oathType
                        property string name: "totp"
                    }
                    RadioButton {
                        id: hotp
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
                        id: six
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
                        id: sha1
                        text: qsTr("SHA-1")
                        exclusiveGroup: algorithm
                        property string name: "SHA1"
                    }
                    RadioButton {
                        id: sha256
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

    MessageDialog {
        id: noQr
        icon: StandardIcon.Warning
        title: qsTr("No QR code found")
        text: qsTr("Could not find a QR code.")
        standardButtons: StandardButton.Ok
    }

    function clear() {
        name.text = ""
        key.text = ""
        oathType.current = totp
        digits.current = six
        algorithm.current = sha1
        touch.checked = false
    }


    function updateForm(uri) {
        if (uri) {
            key.text = uri.secret
            name.text = uri.name
            if (uri.type === "hotp") {
                oathType.current = hotp
            }
            if (uri.digits === "6") {
                digits.current = six
            }
            if (uri.algorithm === 'SHA256') {
                algorithm.current = sha256
            }
        } else {
            noQr.open()
        }
    }

    function addCredential() {
        device.addCredential(name.text, key.text, oathType.current.name,
                             digits.current.digits, algorithm.current.name,
                             touch.checked)
        device.refreshCredentials()
    }
}
