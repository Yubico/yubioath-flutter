import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2

DefaultDialog {
    title: qsTr("Add credential")
    modality: Qt.ApplicationModal
    property var device

    ColumnLayout {
        anchors.fill: parent

        GridLayout {
            columns: 2
            Button {
                id: scanBtn
                focus: true
                Layout.columnSpan: 2
                text: qsTr("Scan a QR code")
                Layout.fillWidth: true
                onClicked: device.parseQr(ScreenShot.capture(), updateForm)
                KeyNavigation.tab: name
                Keys.onEscapePressed: close()
            }
            Label {
                text: qsTr("Name")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.fillWidth: false
            }
            TextField {
                id: name
                Layout.fillWidth: true
                KeyNavigation.tab: key
                Keys.onEscapePressed: close()
            }

            Label {
                text: qsTr("Secret key")
            }
            TextField {
                id: key
                Layout.fillWidth: true
                validator: RegExpValidator {
                    regExp: /[2-7a-zA-Z]+=*/
                }
                KeyNavigation.tab: totp
                Keys.onEscapePressed: close()
                onAccepted: tryAddCredential()
            }
        }

        GroupBox {
            title: qsTr("Credential type")
            Layout.fillWidth: true
            ColumnLayout {

                RowLayout {
                    Label {
                        text: qsTr("OATH Type")
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
                        KeyNavigation.tab: hotp
                        Keys.onEscapePressed: close()
                    }
                    RadioButton {
                        id: hotp
                        text: qsTr("HOTP (Counter based)")
                        exclusiveGroup: oathType
                        property string name: "hotp"
                        KeyNavigation.tab: six
                        Keys.onEscapePressed: close()
                    }
                }
                RowLayout {
                    Label {
                        text: qsTr("Number of digits")
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
                        KeyNavigation.tab: eight
                        Keys.onEscapePressed: close()
                    }
                    RadioButton {
                        id: eight
                        text: qsTr("8")
                        exclusiveGroup: digits
                        property int digits: 8
                        KeyNavigation.tab: sha1
                        Keys.onEscapePressed: close()
                    }
                }
                RowLayout {
                    Label {
                        text: qsTr("Algorithm")
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
                        KeyNavigation.tab: sha256
                        Keys.onEscapePressed: close()
                    }
                    RadioButton {
                        id: sha256
                        text: qsTr("SHA-256")
                        checked: true
                        exclusiveGroup: algorithm
                        property string name: "SHA256"
                        KeyNavigation.tab: touch
                        Keys.onEscapePressed: close()
                    }
                }
                RowLayout {

                    CheckBox {
                        id: touch
                        text: qsTr("Require touch")
                        enabled: enableTouchOption()
                        KeyNavigation.tab: addCredentialBtn
                        Keys.onEscapePressed: close()
                    }
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom
            Button {
                id: addCredentialBtn
                text: qsTr("Add credential")
                enabled: acceptableInput()
                Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                onClicked: tryAddCredential()
                KeyNavigation.tab: cancelBtn
                Keys.onEscapePressed: close()
                isDefault: true
            }
            Button {
                id: cancelBtn
                text: qsTr("Cancel")
                onClicked: close()
                KeyNavigation.tab: scanBtn
                Keys.onEscapePressed: close()
            }
        }
    }

    NoQrDialog {
        id: noQr
    }

    MessageDialog {
        id: paddingError
        icon: StandardIcon.Critical
        title: qsTr("Wrong padding")
        text: qsTr("The padding of the key is incorrect.")
        standardButtons: StandardButton.Ok
    }

    MessageDialog {
        id: spaceError
        icon: StandardIcon.Critical
        title: qsTr("No space")
        text: qsTr("There is no storage space left on the device, so the credential can not be added.")
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

    function tryAddCredential() {
        if (device.credentialExists(name.text)) {
            confirmOverWrite.open()
        } else {
            addCredential()
        }
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
                                 if (error === 'No space') {
                                    spaceError.open()
                                 }
                                 close()
                                 refreshDependingOnMode(true)
                             })
    }
}
