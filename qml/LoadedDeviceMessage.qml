import QtQuick 2.5
import QtQuick.Controls 1.4

Label {

    property var device
    property int nCredentials

    visible: device.hasDevice
    text: getText()

    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap
    width: parent.width
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter

    function getText() {
        if (credentials === null) {
            return qsTr("Reading credentials...")
        } else if (nCredentials === 0 && credentials !== null) {
            return qsTr("No credentials found.")
        } else {
            return ""
        }
    }
}
