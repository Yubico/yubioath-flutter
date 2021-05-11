import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

StyledExpansionPanel {
    label: qsTr("Bio Delete fingerprints")
    visible: settingsPanel.hasPin
    ColumnLayout {
        StyledTextField {
            id: currentPinField
            visible: !!yubiKey.currentDevice && settingsPanel.hasPin
            labelText: qsTr("Current PIN")
        }
        StyledTextField {
            id: templateIdField
            visible: !!yubiKey.currentDevice
            labelText: qsTr("Name of fingerprint")
        }
        RowLayout {
            StyledButton {
                id: applyField
                text: qsTr("Delete")
                enabled: templateIdField.text.length > 15 ? false : true
                onClicked: deleteBio()
            }
        }
    }

    function deleteBio() {
        yubiKey.bioDelete(currentPinField.text, templateIdField.text, function (resp) {
            if (resp.success) {
                navigator.goToSettings()
                navigator.snackBar(qsTr("Fingerprint deleted"))
            } else {
                navigator.snackBarError(qsTr("Fingerprint not deleted"))
            }
        })
    }
}
