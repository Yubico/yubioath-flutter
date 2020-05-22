import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

StyledExpansionPanel {
    id: customReaderPanel
    label: qsTr("Custom reader")
    description: qsTr("Specify a custom reader for YubiKey.")
    metadata: "ccid otp slot custom readers nfc"

    property bool aboutToChange: customReaderCheckbox.checked !== settings.useCustomReader
                                 || readerFilter.text !== settings.customReaderName && readerFilter.text.length > 0

    function isValidMode() {
        return aboutToChange
    }

    function setInterface() {
        settings.useCustomReader = customReaderCheckbox.checked
        settings.customReaderName = readerFilter.text
        yubiKey.clearCurrentDeviceAndEntries()
        yubiKey.refreshDevicesDefault()
        navigator.goToSettings()
        navigator.snackBar(qsTr("Interface changed"))
        isExpanded = false
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
        Layout.fillWidth: true
        StyledCheckBox {
            id: customReaderCheckbox
            checked: settings.useCustomReader
            text: qsTr("Enable custom reader")
            description: qsTr("Useful when using a NFC reader.")
        }
    }

    ColumnLayout {
        Layout.topMargin: 16
        visible: customReaderCheckbox.checked

        RowLayout {
            visible: yubiKey.availableReaders.length > 0
            StyledComboBox {
                id: connectedReaders
                enabled: yubiKey.availableReaders.length > 0
                visible: yubiKey.availableReaders.length > 0
                label: qsTr("Connected readers")
                model: yubiKey.availableReaders
            }
            StyledButton {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                text: qsTr("Use as filter")
                flat: true
                enabled: yubiKey.availableReaders.length > 0
                visible: yubiKey.availableReaders.length > 0
                onClicked: readerFilter.text = connectedReaders.currentText
            }
        }

        StyledTextField {
            id: readerFilter
            labelText: qsTr("Custom reader filter")
            text: settings.customReaderName
        }
    }

    RowLayout {
        Layout.topMargin: 16

        Item {
            Layout.fillWidth: true
        }

        StyledButton {
            Layout.alignment: Qt.AlignRight | Qt.AlignTop
            text: "Apply"
            enabled: isValidMode()
            onClicked: setInterface()
        }
    }
}
