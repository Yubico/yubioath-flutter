import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2

Dialog {
    title: qsTr("Add credential")
    standardButtons: StandardButton.NoButton
    modality: Qt.ApplicationModal
    property var device

    ColumnLayout {
        anchors.fill: parent

        GridLayout {
            columns: 2
            Button {
                Layout.columnSpan: 2
                text: qsTr("Scan a QR code")
                Layout.fillWidth: true
                onClicked: device.parseQr(ScreenShot.capture(), updateForm)
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
                    regExp: /[2-7a-zA-Z]+=*/
                }
            }
        }

        GroupBox {
            title: qsTr("Credential type")
            Layout.fillWidth: true
            ColumnLayout {

                RowLayout {
                    Label {
                        text: "OATH Type"
                    }
                    ExclusiveGroup {
                        id: oathType
                    }
                }
                RowLayout {
                    RadioButton {
                        id: totp
                        text: qsTr("TOTP (Time based)")
                        checked: true
                        exclusiveGroup: oathType
                        property string name: "totp"
                    }
                    RadioButton {
                        id: hotp
                        text: qsTr("HOTP (Counter based)")
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
                }
                RowLayout {
                    RadioButton {
                        id: six
                        text: qsTr("6")
                        checked: true
                        exclusiveGroup: digits
                        property int digits: 6
                    }
                    RadioButton {
                        id: eight
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
                }
                RowLayout {
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
                        enabled: enableTouchOption()
                    }
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom
            Button {
                text: qsTr("Add credential")
                enabled: acceptableInput()
                Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                onClicked: {
                    if (device.credentialExists(name.text)) {
                        confirmOverWrite.open()
                    } else {
                        addCredential()
                    }
                }
            }
            Button {
                text: qsTr("Cancel")
                onClicked: close()
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

    MessageDialog {
        id: paddingError
        icon: StandardIcon.Critical
        title: qsTr("Wrong padding")
        text: qsTr("The padding of the key is incorrect.")
        standardButtons: StandardButton.Ok
    }

    MessageDialog {
        id: confirmOverWrite
        icon: StandardIcon.Warning
        title: qsTr("Overwrite credential?")
        text: qsTr("A credential with this name already exists. Are you sure you want to overwrite this credential?")
        standardButtons: StandardButton.Ok | StandardButton.Cancel
        onAccepted: addCredential()
    }

    function clear() {
        name.text = ""
        key.text = ""
        oathType.current = totp
        digits.current = six
        algorithm.current = sha1
        touch.checked = false
    }

    function enableTouchOption() {
        return parseInt(device.version.split('.').join('')) >= 426
    }

    function acceptableInput() {
        return name.text.length !== 0 && key.text.length !== 0
    }

    function updateForm(uri) {
        if (uri) {

            name.text = uri.name
            if (uri.algorithm === 'SHA256') {
                algorithm.current = sha256
            }
            if (uri.type === "hotp") {
                oathType.current = hotp
            }
            if (uri.digits === "6") {
                digits.current = six
            }
            if (uri.digits === "8") {
                digits.current = eight
            }

            key.text = uri.secret
        } else {
            noQr.open()
        }
    }

    function addCredential() {
        device.addCredential(name.text, key.text, oathType.current.name,
                             digits.current.digits, algorithm.current.name,
                             touch.checked, function (error) {
                                 if (error === 'Incorrect padding') {
                                     paddingError.open()
                                 }
                                 close()
                                 refreshDependingOnMode(true)
                             })
    }
}
