import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import "utils.js" as Utils


// Heavily based on http://www.bytebau.com/progress-circle-with-qml-and-javascript/
Item {

    property int period
    property var code
    signal timesUp

    Timer {
        id: timer
        repeat: true
        running: code && code.valid_to ? true : false
        interval: 250
        onTriggered: {
            var timeLeft = code.valid_to - Utils.getNow()
            var currentValue = timeLeft * (360 / period)
            root.arcEnd = 360 - currentValue
            if (timeLeft === 0) {
                timesUp()
            }
        }
    }

    id: root
    width: size
    height: size

    property int size: 12
    property real arcBegin: 0
    property real arcEnd: 0
    property string colorCircle

    onArcBeginChanged: canvas.requestPaint()
    onArcEndChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        rotation: -90
        onPaint: {
            var ctx = getContext("2d")
            var x = width / 2
            var y = height / 2
            var start = Math.PI * (parent.arcBegin / 180)
            var end = Math.PI * (parent.arcEnd / 180)
            ctx.reset()
            ctx.beginPath()
            ctx.fillStyle = root.colorCircle
            ctx.moveTo(x, y)
            ctx.arc(x, y, width / 2, end, start, false)
            ctx.lineTo(x, y)
            ctx.fill()
        }
    }
}
