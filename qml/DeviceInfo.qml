import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1

Item {
    property var device
    property int margin: width / 30

    width: 200
    height: 200

    ColumnLayout {

        GroupBox {
            id: deviceBox
            title: qsTr("Device")
            Layout.fillWidth: true
            anchors.topMargin: margin
            anchors.top: parent.top

            GridLayout {
                anchors.fill: parent
                columns: 1

                Label {
                    text: device.name
                }

                Label {
                    text: qsTr("Firmware: ") + device.version
                }

                Label {
                    visible: device.serial
                    text: qsTr("Serial: ") + device.serial
                }
            }
        }
    }
}
