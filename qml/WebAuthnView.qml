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
    property bool hasPin: yubiKey.currentDevice.fidoHasPin
    property bool pinBlocked: yubiKey.currentDevice.pinBlocked
    property int pinRetries: yubiKey.currentDevice.fidoPinRetries

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
                label: hasPin ? qsTr("Change PIN") : qsTr("Set PIN")
                description: qsTr("Protect your security key with a PIN")
                isFlickable: true
            }
            StyledExpansionPanel {
                label: qsTr("Sign-in data")
                description: qsTr("View and delete sign-in data stored on your security key")
                isFlickable: true
            }
            StyledExpansionPanel {
                label: qsTr("Fingerprints")
                description: qsTr("Add and delete fingerprints")
                isFlickable: true
            }
            StyledExpansionPanel {
                label: qsTr("Reset")
                description: qsTr("This will delete all data on the security key")
                isFlickable: true
            }
        }
    }
}
