import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1

Item {
    property var device

    width: parent.width
    height: parent.height

    ColumnLayout {

        Timer {
            id: oathTimer
            triggeredOnStart: true
            interval: 30000
            repeat: true
            running: true
            onTriggered: device.refresh_credentials()
        }

        Repeater {
            model: device.credentials

            ColumnLayout {

                Text {
                    text: qsTr('') + modelData[0]
                }

                Text {
                    text: qsTr('') + modelData[1]
                    font.bold: true
                }
            }
        }
    }
}
