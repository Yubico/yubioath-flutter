import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2

DefaultDialog {
    title: qsTr("New credential")
    modality: Qt.ApplicationModal

    property var settings
    property var device

    ColumnLayout {
        anchors.fill: parent

        GridLayout {
            columns: 2
            Label {
                text: qsTr("Secret key")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            TextField {
                id: key
                Layout.fillWidth: true
                validator: RegExpValidator {
                    regExp: /[2-7a-zA-Z ]+=*/
                }
                focus: true
                Keys.onEscapePressed: close()
                onAccepted: tryAddCredential()
            }
            Label {
                text: qsTr("YubiKey Slot")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            ComboBox {
                id: slotSelected
                Layout.fillWidth: true
                currentIndex: 0
                model: ListModel {
                    id: slotItems

                    ListElement {
                        text: qsTr("Slot 1")
                        slotNumber: 1
                    }
                    ListElement {
                        text: qsTr("Slot 2")
                        slotNumber: 2
                    }
                }
            }
            Label {
                text: qsTr("Require touch")
                Layout.alignment: Qt.AlignRight
            }
            CheckBox {
                id: touch
                KeyNavigation.tab: addCredentialBtn
                Keys.onEscapePressed: close()
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom
            Button {
                id: cancelBtn
                text: qsTr("Cancel")
                onClicked: close()
                KeyNavigation.tab: key
                Keys.onEscapePressed: close()
            }
            Button {
                id: addCredentialBtn
                text: qsTr("Save credential")
                enabled: acceptableInput()
                Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                onClicked: tryAddCredential()
                KeyNavigation.tab: cancelBtn
                Keys.onEscapePressed: close()
                isDefault: true
            }
        }
    }

    MessageDialog {
        id: paddingError
        icon: StandardIcon.Critical
        title: qsTr("Wrong padding")
        text: qsTr("The padding of the key is incorrect.")
        standardButtons: StandardButton.Ok
    }

    MessageDialog {
        id: tooLargeKeyError
        icon: StandardIcon.Critical
        title: qsTr("Too large key")
        text: qsTr("YubiKey Slots cannot handle TOTP keys over 20 bytes.")
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

    function getSelectedSlotNumber() {
        return slotItems.get(slotSelected.currentIndex).slotNumber
    }

    function tryAddCredential() {
        if (slotIsUsed(getSelectedSlotNumber())) {
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
        return key.text.length !== 0 && getSelectedSlotNumber() !== null
    }

    function updateForm(uri) {
        if (uri) {
            key.text = uri.secret
        } else {
            noQr.open()
        }
    }

    function addCredential() {
        device.addSlotCredential(getSelectedSlotNumber(), key.text,
                                 touch.checked, function (error) {
                                     if (error === 'Incorrect padding') {
                                         paddingError.open()
                                     }
                                     if (error === 'Over 20 bytes') {
                                         tooLargeKeyError.open()
                                     }
                                     if (error) {
                                         console.log(error)
                                     }
                                     close()
                                     refreshDependingOnMode(true)
                                 })
    }
}
