import QtQuick 2.5
import QtQuick.Controls 1.4
import "utils.js" as Utils

Label {

    property var device
    property var settings
    property bool ccidMode: !settings.slotMode

    visible: !device.hasDevice
    text: getText()
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap
    width: parent.width
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter

    function getText() {
        if (device.nDevices === 0) {
            return qsTr("No YubiKey detected.")
        } else if (device.nDevices === 1) {
            if (device.unusableDeviceDescription) {
                switch (device.unusableDeviceDescription.pid) {
                case 288:
                    // FIDO U2F Security Key by Yubico
                    return qsTr("The connected device is a %1. This device cannot be used with Yubico Authenticator.").arg(
                                device.unusableDeviceDescription.type)
                default:
                    if (settings.slotMode && !device.hasOTP) {
                        return qsTr("Authenticator mode is set to YubiKey slots, but the OTP connection mode is not enabled.")
                    } else if (ccidMode && !device.hasCCID) {
                        return qsTr("Authenticator mode is set to CCID, but the CCID connection mode is not enabled.")
                    } else {
                        return qsTr("The connected device cannot be used with Yubico Authenticator.")
                    }
                }
            } else {
                return qsTr("Connecting to YubiKey...")
            }
        } else if (device.nDevices > 1) {
            return qsTr("Multiple YubiKeys detected!")
        }
    }
}
