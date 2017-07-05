import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2

DefaultDialog {
    title: qsTr("Add credential")
    modality: Qt.ApplicationModal

    property var settings
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
                KeyNavigation.tab: slot1
                Keys.onEscapePressed: close()
                onAccepted: tryAddCredential()
            }
        }

        ColumnLayout {
            Label {
                text: qsTr("YubiKey Slot")
            }
            ExclusiveGroup {
                id: slotSelected
            }
            RadioButton {
                id: slot1
                enabled: settings.slot1
                text: qsTr("Slot 1") + (device.slot1inUse ? qsTr(" (in use)") : '')
                checked: true
                exclusiveGroup: slotSelected
                property string name: "1"
                KeyNavigation.tab: slot2
                Keys.onEscapePressed: close()
            }
            RadioButton {
                id: slot2
                enabled: settings.slot2
                text: qsTr("Slot 2") + (device.slot2inUse ? qsTr(" (in use)") : '')
                exclusiveGroup: slotSelected
                property string name: "2"
                KeyNavigation.tab: touch
                Keys.onEscapePressed: close()
            }
        }

        ColumnLayout {

            RowLayout {
                CheckBox {
                    id: touch
                    text: "Require touch"
                    KeyNavigation.tab: addCredentialBtn
                    Keys.onEscapePressed: close()
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
        id: confirmOverWrite
        icon: StandardIcon.Warning
        title: qsTr("Overwrite credential?")
        text: qsTr("This slot seems to already be configured. Are you sure you want to overwrite the slot configuration?")
        standardButtons: StandardButton.Ok | StandardButton.Cancel
        onAccepted: addCredential()
    }

    function tryAddCredential() {
        if (slotIsUsed(slotSelected.current.name)) {
            confirmOverWrite.open()
        } else {
            addCredential()
        }
    }

    function slotIsUsed(slot) {
        return slot === "1" && device.slot1inUse || slot === "2"
                && device.slot2inUse
    }

    function clear() {
        key.text = ""
        touch.checked = false
    }

    function acceptableInput() {
        return key.text.length !== 0 && slotSelected.current !== null
    }

    function updateForm(uri) {
        if (uri) {
            key.text = uri.secret
        } else {
            noQr.open()
        }
    }

    function addCredential() {
        device.addSlotCredential(slotSelected.current.name, key.text,
                                 touch.checked, function (error) {
                                     if (error === 'Incorrect padding') {
                                         paddingError.open()
                                     }
                                     if (error) {
                                         console.log(error)
                                     }
                                     close()
                                     refreshDependingOnMode(true)
                                 })
    }
}
