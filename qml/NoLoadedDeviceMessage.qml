import QtQuick 2.5
import QtQuick.Controls 1.4

Label {

    property var device

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
            return qsTr("Connecting to YubiKey...")
        } else if (device.nDevices > 1){
            return qsTr("Multiple YubiKeys detected!")
        }
    }
}
