import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4

Column {
    property var device
    width: parent.width
   // anchors.fill: parent.width
    height: parent.height
    property int margin: width / 30

    ColumnLayout {

        ProgressBar {
                id: bar
                value: 30
                maximumValue: 30
                minimumValue: 0

                style: ProgressBarStyle {
                    progress: Rectangle {
                               color: "#83d714"
                    }

                    background: Rectangle {
                        radius: 2
                        color: "lightgray"
                        border.color: "gray"
                        border.width: 0
                        implicitWidth: 300
                        implicitHeight: 10
                    }

                }

                Timer {
                    interval: 1000
                    repeat: true
                    running: true
                    onTriggered: bar.value > bar.minimumValue ? bar.value -= 1 : bar.value = bar.maximumValue
                }
            }

        Timer {
            id: oathTimer
            triggeredOnStart: true
            interval: 30000
            repeat: true
            running: true
            onTriggered: {device.refresh_credentials(); bar.value = 0}
        }

        Repeater {
            model: device.credentials

            Column {
                Text {
                    text: qsTr('') + modelData[0]
                }
                Text {
                    text: qsTr('') + modelData[1]
                    font.family: "Chalkboard"
                    font.bold: true
                    font.pointSize: 20
                }
            }
        }
    }
}
