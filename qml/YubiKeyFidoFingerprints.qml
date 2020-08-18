import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

StyledExpansionPanel {
    label: qsTr("Fingerprints")
    description: qsTr("Add and delete fingerprints saved on your security key")
    isVisible: yubiKey.currentDeviceEnabled("FIDO2")
}
