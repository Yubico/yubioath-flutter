import QtQuick 2.0

Text {

    property var device
    property int nCredentials
    property var settings
    property bool ccidMode: !settings.slotMode
    property bool readingCredentials

    visible: device.hasDevice
    text: getText()

    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap
    width: parent.width
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter

    function getText() {
        if (settings.slotMode && !device.hasOTP) {
            return qsTr("Authenticator mode is set to YubiKey slots, but the OTP connection mode is not enabled.")
        } else if (ccidMode && !device.hasCCID) {
            return qsTr("Authenticator mode is set to CCID, but the CCID connection mode is not enabled.")
        } else if (readingCredentials) {
                return qsTr("Reading credentials...")
        } else if (nCredentials === 0 && !readingCredentials) {
                return qsTr("No credentials found.")
        } else {
            return ""
        }
    }
}
