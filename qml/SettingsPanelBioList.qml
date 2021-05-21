import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

StyledExpansionPanel {
    label: qsTr("Bio list fingerprints")
    visible: settingsPanel.hasPin
    ColumnLayout {
        StyledTextField {
            id: currentPinField
            visible: !!yubiKey.currentDevice && settingsPanel.hasPin
            labelText: qsTr("Current PIN")
        }
        RowLayout {
            StyledButton {
                id: applyField
                text: qsTr("List")
                onClicked: yubiKey.fidoList(currentPinField.text)

            }
        }
    }
}
