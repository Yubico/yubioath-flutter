import QtQuick 2.5
import QtQuick.Controls 1.4

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
            if (settings.slotMode && device.enabled && !device.hasOTP) {
                return qsTr("Authenticator mode is set to YubiKey slots, but the OTP connection mode is not enabled.")
            } else if (ccidMode && device.enabled && device.hasCCID) {
                return qsTr("Authenticator mode is set to CCID, but the CCID connection mode is not enabled.")
            } else {
                return qsTr("Connecting to YubiKey...")
            }
        } else if (device.nDevices > 1) {
            return qsTr("Multiple YubiKeys detected!")
        }
    }
}
