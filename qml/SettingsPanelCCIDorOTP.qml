import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

StyledExpansionPanel {
    id: interfacePanel
    label: qsTr("Interface")
    description: qsTr("Configure how to communicate with the YubiKey.")
    visible: !settings.useCustomReader
    property bool otpModeSelected: interfaceCombobox.currentIndex === 1 // interfaceCombobox.currentIndex === 2
    //property bool customReaderSelected: interfaceCombobox.currentIndex === 1
    property bool aboutToChange: (otpModeSelected !== settings.otpMode)
                                 || (slot1DigitsComboBox.currentIndex
                                     !== getComboBoxIndex(
                                         settings.slot1digits))
                                 || (slot2DigitsComboBox.currentIndex
                                     !== getComboBoxIndex(
                                         settings.slot2digits))
                                 //|| customReaderSelected !== settings.useCustomReader
                                 //|| readerFilter.text !== settings.customReaderName && readerFilter.text.length > 0

    ListModel {
        id: otpModeDigits

        ListElement {
            text: "Off"
            value: 0
        }
        ListElement {
            text: "6"
            value: 6
        }
        ListElement {
            text: "7"
            value: 7
        }
        ListElement {
            text: "8"
            value: 8
        }
    }


    function isValidMode() {
        return aboutToChange
                && ((otpModeSelected
                     && (slot1DigitsComboBox.currentIndex !== 0
                         || slot2DigitsComboBox.currentIndex !== 0))
                    || !otpModeSelected)
    }

    function setInterface() {
        settings.slot1digits = otpModeDigits.get(
                    slot1DigitsComboBox.currentIndex).value
        settings.slot2digits = otpModeDigits.get(
                    slot2DigitsComboBox.currentIndex).value
        settings.otpMode = otpModeSelected
        //settings.useCustomReader = customReaderSelected
        //settings.customReaderName = readerFilter.text
        yubiKey.clearCurrentDeviceAndEntries()
        yubiKey.oathCalculateAllOuter()
        navigator.goToSettings()
        navigator.snackBar(qsTr("Interface changed"))
        interfacePanel.isExpanded = false
    }

    function getComboBoxIndex(digits) {
        switch (digits) {
        case 0:
            return 0
        case 6:
            return 1
        case 7:
            return 2
        case 8:
            return 3
        default:
            return 0
        }
    }

    ColumnLayout {


        RowLayout {
            Layout.fillWidth: true
            StyledComboBox {
                id: interfaceCombobox
                label: qsTr("Interface")
                model: ["CCID (recommended)", "OTP"] //["CCID (recommended)", "CCID with custom reader", "OTP"]
                currentIndex: getCurrentIndex()

                function getCurrentIndex() {
                    if (settings.otpMode) {
                        return 1 //return 2
                    }
                    /*if (settings.useCustomReader && !settings.otpMode) {
                        return 1
                    }*/
                    // default
                    return 0
                }
            }
        }
    }

    RowLayout {
        visible: interfacePanel.otpModeSelected
        Label {
            Layout.fillWidth: true
            font.pixelSize: 12
            color: primaryColor
            opacity: lowEmphasis
            text: qsTr("Using OTP slots should be considered for special cases only.")
            wrapMode: Text.WordWrap
            Layout.rowSpan: 1
            bottomPadding: 8
        }
    }

    RowLayout {
        visible: interfacePanel.otpModeSelected

        StyledComboBox {
            id: slot1DigitsComboBox
            label: qsTr("Slot 1 digits")
            comboBox.textRole: "text"
            model: otpModeDigits
            currentIndex: interfacePanel.getComboBoxIndex(
                              settings.slot1digits)
        }

        Item {
            width: 16
        }

        StyledComboBox {
            id: slot2DigitsComboBox
            label: qsTr("Slot 2 digits")
            comboBox.textRole: "text"
            model: otpModeDigits
            currentIndex: interfacePanel.getComboBoxIndex(
                              settings.slot2digits)
        }
    }

    /*ColumnLayout {
        visible: interfacePanel.customReaderSelected

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
                Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                text: qsTr("Use as filter")
                flat: true
                enabled: yubiKey.availableReaders.length > 0
                visible: yubiKey.availableReaders.length > 0
                onClicked: readerFilter.text = connectedReaders.currentText
            }
        }

        StyledTextField {
            id: readerFilter
            enabled: interfacePanel.customReaderSelected
            visible: interfacePanel.customReaderSelected
            labelText: qsTr("Custom reader filter")
            text: settings.customReaderName
        }
    }*/

    StyledButton {
        Layout.alignment: Qt.AlignRight | Qt.AlignTop
        text: "Apply"
        enabled: interfacePanel.isValidMode()
        onClicked: interfacePanel.setInterface()
    }
}
