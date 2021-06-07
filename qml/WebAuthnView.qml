import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {

    id: settingsPanel
    objectName: 'yubiKeyWebAuthnView'
    contentWidth: app.width
    contentHeight: expandedHeight

    property var expandedHeight: content.implicitHeight + dynamicMargin
    property bool hasPin: !!yubiKey.currentDevice && yubiKey.currentDevice.fidoHasPin
    property bool pinBlocked: !!yubiKey.currentDevice && yubiKey.currentDevice.pinBlocked
    property int pinRetries: !!yubiKey.currentDevice && yubiKey.currentDevice.fidoPinRetries

    onExpandedHeightChanged: {
        if (expandedHeight > app.height - toolBar.height) {
             scrollBar.active = true
         }
    }

    ScrollBar.vertical: ScrollBar {
        id: scrollBar
        width: 8
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        hoverEnabled: true
        z: 2
    }
    boundsBehavior: Flickable.StopAtBounds

    property string searchFieldPlaceholder: "" // qsTr("Search configuration")

    ColumnLayout {
        width: settingsPanel.contentWidth
        id: content
        spacing: 0

        StyledExpansionContainer {
            title: qsTr("WebAuthn (FIDO2/U2F)")

            StyledExpansionPanel {
                label: qsTr("Protect your YubiKey")
                isEnabled: false
                actionButton.text: hasPin ? qsTr("Change PIN") : qsTr("Create a PIN")
                actionButton.onClicked: navigator.confirmInput({
                    "pinMode": true,
                    "manageMode": true,
                    "heading": actionButton.text,
                })
            }
            StyledExpansionPanel {
                label: qsTr("Sign-in data")
                visible: !!yubiKey.currentDevice && yubiKey.currentDeviceEnabled("FIDO2")
                enabled: !!yubiKey.currentDevice && yubiKey.currentDevice.fidoHasPin
                description: qsTr("View and delete sign-in data stored on your security key")
                isFlickable: true
                expandButton.onClicked: navigator.confirmInput({
                    "pinMode": true,
                    "heading": label,
                    "acceptedCb": function() {
                        console.log("PIN OK")
                    }
                })
            }
            StyledExpansionPanel {
                label: qsTr("Fingerprints")
                visible: !!yubiKey.currentDevice && yubiKey.currentDeviceEnabled("FIDO2") && yubiKey.currentDevice.name.toUpper() === "YUBIKEY BIO"
                enabled: !!yubiKey.currentDevice && yubiKey.currentDevice.fidoHasPin
                description: qsTr("Add and delete fingerprints")
                isFlickable: true
                expandButton.onClicked: navigator.confirmInput({
                    "pinMode": true,
                    "heading": label,
                    "acceptedCb": function() {
                        console.log("PIN OK")
                    }
                })
            }
            StyledExpansionPanel {
                id: savedPasswordsPanel
                label: qsTr("Factory defaults")
                isEnabled: false
                actionButton.text: "Reset"
                actionButton.onClicked: navigator.confirm({
                    "heading": qsTr("Reset device?"),
                    "message": qsTr("This will delete all accounts and restore factory defaults of your YubiKey."),
                    "description": qsTr("Before proceeding:<ul style=\"-qt-list-indent: 1;\"><li>There is NO going back after a factory reset.<li>If you do not know what you are doing, do NOT do this.</ul>"),
                    "buttonAccept": qsTr("Reset device"),
                    "acceptedCb": function () {
                        console.log("FIDO2 Reset")
                    }
                })
            }
        }
    }
}
