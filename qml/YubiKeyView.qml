import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {
    id: panel
    objectName: 'yubiKeyView'
    contentWidth: app.width
    contentHeight: content.visible ? content.height + dynamicMargin : app.height - toolBar.height
    leftMargin: 0
    rightMargin: 0

    onContentHeightChanged: {
        if (contentHeight > app.height - toolBar.height) {
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

    Accessible.ignored: true

    property string searchFieldPlaceholder: ""

    property string deviceName: !!yubiKey.currentDevice ? yubiKey.currentDevice.name : ""
    property string deviceSerial: !!yubiKey.currentDevice && !!yubiKey.currentDevice.serial ? yubiKey.currentDevice.serial : ""
    property string deviceVersion: !!yubiKey.currentDevice && !!yubiKey.currentDevice.version ? yubiKey.currentDevice.version : ""
    property string deviceImage: !!yubiKey.currentDevice ? yubiKey.getCurrentDeviceImage() : ""

    function getDisabledMessage(application) {
        if(!yubiKey.currentDeviceSupported(application)) {
            return "Application unavailable on YubiKey"
        }
        if(!yubiKey.currentDeviceEnabled(application)) {
            return "Application disabled on YubiKey"
        }
        if(application == "FIDO2" && yubiKey.isWinNonAdmin) {
            return "Launch app as administrator to access"
        }
        return "Application not accessible"
    }

    NoYubiKeySection {
        id: noYubiKeySection
        // Make this section the default view to show when there is errors.
        visible: yubiKey.availableDevices.length === 0
        enabled: visible
        Accessible.ignored: true
    }

    ColumnLayout {
        id: content
        visible: !noYubiKeySection.visible

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: app.width < dynamicWidth
               ? app.width
               : dynamicWidth

        ColumnLayout {
            id: deviceInfo
            visible: !toolBar.searchField.text.length > 0
            spacing: 4
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            width: parent.width
            Layout.leftMargin: 0
            Layout.topMargin: 32
            Layout.rightMargin: 0
            Layout.bottomMargin: 0

            Rectangle {
                width: 120
                height: 120
                color: formHighlightItem
                radius: width * 0.5
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    sourceSize.width: parent.width - 20
                    source: deviceImage
                    fillMode: Image.PreserveAspectFit
                    visible: parent.visible
                }
            }

            StyledExpansionContainer {
                title: qsTr("Information")

                StyledExpansionPanel {
                    id: expansionPanel
                    isEnabled: false
                    isExpanded: true
                    isTopPanel: true

                    StyledTextField {
                        labelText: qsTr("Device type")
                        text: deviceName
                        visible: text.length > 0
                        enabled: false
                        noedit: true
                    }
                    StyledTextField {
                        labelText: qsTr("Firmware version")
                        text: deviceVersion
                        visible: text.length > 0
                        enabled: false
                        noedit: true
                    }
                    StyledTextField {
                        labelText: qsTr("Serial number")
                        text: deviceSerial
                        visible: text.length > 0
                        enabled: false
                        noedit: true
                    }
                }
            }
        }

        ColumnLayout {
            id: deviceConfig
            spacing: 0
            width: parent.width
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop

            StyledExpansionContainer {
                title: qsTr("Configuration")

                StyledExpansionPanel {
                    label: qsTr("WebAuthn (FIDO2/U2F)")
                    description: enabled ? qsTr("Manage PIN, fingerprints and credentials stored on the YubiKey") : getDisabledMessage("FIDO2")
                    enabled: !!yubiKey.currentDevice && yubiKey.currentDevice.ctapAvailable
                    toolButtonIcon: !enabled && yubiKey.currentDeviceSupported("FIDO2") || yubiKey.currentDeviceSupported("U2F") ? "../images/warning.svg" : ""
                    isFlickable: true
                    isEnabled: enabled
                    expandButton.onClicked: navigator.goToWebAuthnView()
                }
/*
                StyledExpansionPanel {
                    label: qsTr("Smart card (PIV)")
                    description: enabled ? qsTr("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod") : getDisabledMessage("PIV")
                    enabled: yubiKey.currentDeviceEnabled("PIV")
                    toolButtonIcon: !enabled && yubiKey.currentDeviceSupported("PIV") ? "../images/warning.svg" : ""
                    isEnabled: enabled
                    isFlickable: true
                }
                StyledExpansionPanel {
                    label: qsTr("One-time password (OTP)")
                    description: enabled ? qsTr("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod") : getDisabledMessage("OTP")
                    enabled: yubiKey.currentDeviceEnabled("OTP")
                    toolButtonIcon: !enabled && yubiKey.currentDeviceSupported("OTP") ? "../images/warning.svg" : ""
                    isEnabled: enabled
                    isFlickable: true
                    expandButton.onClicked: navigator.goToOneTimePasswordView()
                }
*/
             }
        }
    }
}
