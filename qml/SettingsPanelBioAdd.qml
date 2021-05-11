import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

StyledExpansionPanel {
    label: qsTr("Bio Add fingerprints")
    visible: settingsPanel.hasPin
    ColumnLayout {
        StyledTextField {
            id: currentPinField
            visible: !!yubiKey.currentDevice && settingsPanel.hasPin
            labelText: qsTr("Current PIN")
        }
        StyledTextField {
            id: nameField
            visible: !!yubiKey.currentDevice
            labelText: qsTr("Name of fingerprint")
        }
        RowLayout {
            StyledButton {
                id: applyField
                text: qsTr("Add")
                enabled: nameField.text.length > 15 ? false : true
                onClicked: enroll()

            }
        }
    }

    function enroll() {
        yubiKey.bioEnroll(currentPinField.text, nameField.text, function (resp) {
            if (resp.success) {
                navigator.goToSettings()
                navigator.snackBar(qsTr("Fingerprint added"))
            } else {
                navigator.snackBarError(qsTr("Fingerprint not added"))
            }
        })
    }
}
