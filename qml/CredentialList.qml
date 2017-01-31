import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4

Column {
    property var device
    width: parent.width
    height: parent.height
    property int margin: width / 30

    ColumnLayout {

        ProgressBar {
                id: bar
                value: 0
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
                    triggeredOnStart: true
                    onTriggered: update()
                }
            }

        Repeater {
            model: device.credentials

            Column {
                Text {
                    text: qsTr('') + JSON.parse(modelData)['name']
                }
                Text {
                    text: qsTr('') + JSON.parse(modelData)['code']
                    font.family: "Chalkboard"
                    font.bold: true
                    font.pointSize: 20
                }
            }
        }
    }

    function update() {
        if (bar.value > bar.minimumValue) {
            bar.value -= 1;
        }
        if (bar.value == bar.minimumValue) {
            device.refresh_credentials()
            bar.value = bar.maximumValue
        }
    }

}
