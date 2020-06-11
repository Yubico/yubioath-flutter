import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {
    id: panel
    objectName: 'yubiKeyView'
    contentWidth: app.width - 32
    contentHeight: content.visible ? content.implicitHeight + 32 : app.height - toolBar.height
    leftMargin: 16
    rightMargin: 16

    readonly property int dynamicWidth: 648
    readonly property int dynamicMargin: 32

    ScrollBar.vertical: ScrollBar {
        width: 8
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        hoverEnabled: true
        z: 2
    }
    boundsBehavior: Flickable.StopAtBounds

    Keys.onEscapePressed: navigator.home()

    Accessible.ignored: true

    property string title: ""

    property string deviceName: !!yubiKey.currentDevice ? yubiKey.currentDevice.name : ""
    property string deviceSerial: !!yubiKey.currentDevice && !!yubiKey.currentDevice.serial ? yubiKey.currentDevice.serial : ""
    property string deviceVersion: !!yubiKey.currentDevice && !!yubiKey.currentDevice.version ? yubiKey.currentDevice.version : ""
    property string deviceImage: !!yubiKey.currentDevice ? yubiKey.getCurrentDeviceImage() : ""
    property string deviceFormFactor: !!yubiKey.currentDevice
                                      && yubiKey.currentDevice.usbInterfacesEnabled.join(', ')
                                     .replace("CCID","Smart card (CCID)")
                                     .replace("FIDO","WebAuthn (FIDO)")

    function getFormFactor() {
        if (!!(yubiKey.currentDevice)) {
            const formfactor = {
                USB_A_KEYCHAIN: 0x01,
                USB_A_NANO: 0x02,
                USB_C_KEYCHAIN: 0x03,
                USB_C_NANO: 0x04,
                USB_C_LIGHTNING: 0x05
            }

            switch (yubiKey.currentDevice.formFactor) {
                case formfactor.USB_A_KEYCHAIN:
                    return 'Keychain (USB-A)'
                case formfactor.USB_A_NANO:
                    return 'Nano (USB-A)'
                case formfactor.USB_C_KEYCHAIN:
                    return 'Keychain (USB-C)'
                case formfactor.USB_C_NANO:
                    return 'Nano (USB-C)'
                case formfactor.USB_C_LIGHTNING:
                    return 'Keychain (USB-C, Lightning)'
                default:
                    return ''
            }
        }
        return ''
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
        spacing: 4
        width: app.width - dynamicMargin
               < dynamicWidth ? app.width - dynamicMargin : dynamicWidth

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

        Label {
            text: "Device information"
            font.pixelSize: 16
            font.weight: Font.Normal
            lineHeight: 1.8
            Layout.topMargin: 24
            color: yubicoGreen
            opacity: fullEmphasis
        }
        StyledTextField {
            labelText: qsTr("Device type")
            text: deviceName
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
        StyledTextField {
            labelText: qsTr("Firmware version")
            text: deviceVersion
            visible: text.length > 0
            enabled: false
            noedit: true
        }
        StyledTextField {
            labelText: qsTr("Form factor")
            text: getFormFactor()
            visible: text.length > 0
            enabled: false
            noedit: true
        }
        Label {
            text: "Configurable settings"
            font.pixelSize: 16
            font.weight: Font.Normal
            lineHeight: 1.8
            Layout.topMargin: 16
            color: yubicoGreen
            opacity: fullEmphasis
            visible: usbInterfaces.visible || nfcInterfaces.visible
        }
        StyledTextField {
            id: usbInterfaces
            labelText: qsTr("Enabled USB interfaces")
            text: deviceFormFactor
            visible: text.length > 0
            enabled: false
            noedit: true
        }
        StyledTextField {
            id: nfcInterfaces
            labelText: qsTr("NFC interface")
            text: !!yubiKey.currentDevice && yubiKey.currentDevice.nfcAppEnabled.length > 0
                  ? "Enabled"
                  : "Disabled"
            visible: !!yubiKey.currentDevice && yubiKey.currentDevice.nfcAppSupported.length > 0
            enabled: false
            noedit: true
        }
    }
}
