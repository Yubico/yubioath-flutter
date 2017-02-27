import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2

Dialog {
    title: qsTr("Add credential")
    standardButtons: StandardButton.NoButton
    modality: Qt.ApplicationModal
    onAccepted: addCredential()

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
                visible: !settings.slotMode
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.fillWidth: false
            }
            TextField {
                id: name
                visible: !settings.slotMode
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


            ColumnLayout {
                Label {
                    text: qsTr("YubiKey Slot")
                    visible: settings.slotMode
                }
                ExclusiveGroup {
                    id: slotSelected
                }
                RadioButton {
                    id: slot1
                    visible: settings.slotMode
                    enabled: settings.slot1
                    text: qsTr("Slot 1")
                    checked: true
                    exclusiveGroup: slotSelected
                    property string name: "1"
                }
                RadioButton {
                    id: slot2
                    visible: settings.slotMode
                    enabled: settings.slot2
                    text: qsTr("Slot 2")
                    exclusiveGroup: slotSelected
                    property string name: "2"
                }
            }


        GroupBox {
            title: qsTr("Credential type")
            Layout.fillWidth: true
            visible: !settings.slotMode
            ColumnLayout {

                RowLayout {
                    Label {
                        visible: !settings.slotMode
                        text: "OATH Type"
                    }
                    ExclusiveGroup {
                        id: oathType
                    }
                    RadioButton {
                        id: totp
                        visible: !settings.slotMode
                        text: qsTr("Time based (TOTP)")
                        checked: true
                        exclusiveGroup: oathType
                        property string name: "totp"
                    }
                    RadioButton {
                        id: hotp
                        visible: !settings.slotMode
                        text: qsTr("Counter based (HOTP)")
                        exclusiveGroup: oathType
                        property string name: "hotp"
                    }
                }
                RowLayout {
                    Label {
                        text: "Number of digits"
                        visible: !settings.slotMode
                    }
                    ExclusiveGroup {
                        id: digits
                    }
                    RadioButton {
                        id: six
                        visible: !settings.slotMode
                        text: qsTr("6")
                        checked: true
                        exclusiveGroup: digits
                        property int digits: 6
                    }
                    RadioButton {
                        id: eight
                        visible: !settings.slotMode
                        text: qsTr("8")
                        exclusiveGroup: digits
                        property int digits: 8
                    }
                }
                RowLayout {
                    Label {
                        text: "Algorithm"
                        visible: !settings.slotMode
                    }
                    ExclusiveGroup {
                        id: algorithm
                    }
                    RadioButton {
                        id: sha1
                        visible: !settings.slotMode
                        text: qsTr("SHA-1")
                        exclusiveGroup: algorithm
                        property string name: "SHA1"
                    }
                    RadioButton {
                        id: sha256
                        visible: !settings.slotMode
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
                onClicked: accept()
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

    function clear() {
        name.text = ""
        key.text = ""
        oathType.current = totp
        digits.current = six
        algorithm.current = sha1
        touch.checked = false
    }

    function enableTouchOption() {
        if (settings.slotMode) {
            return true
        } else {
            return parseInt(device.version.split('.').join('')) >= 426
        }
    }


    function acceptableInput(){
        if (!settings.slotMode) {
            return name.text.length !== 0 && key.text.length !== 0
        }
        if (settings.slotMode) {
            return key.text.length !== 0 && slotSelected.current !== null
        }
    }

    function updateForm(uri) {
        if (uri) {
            if (!settings.slotMode) {
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
            }

            key.text = uri.secret

        } else {
            noQr.open()
        }
    }

    function addCredential() {
        if (settings.slotMode) {
            device.addSlotCredential(slotSelected.current.name, key.text, touch.checked, function(error) {
                if (error === 'Incorrect padding') {
                    paddingError.open()
                }
                if (error) {
                    console.log(error)
                }
            })
        } else {
        device.addCredential(name.text, key.text, oathType.current.name,
                             digits.current.digits, algorithm.current.name,
                             touch.checked, function (error) {
                                 if (error === 'Incorrect padding') {
                                     paddingError.open()
                                 }
                             })
        }
    }
}
