import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import "utils.js" as Utils


// Heavily based on http://www.bytebau.com/progress-circle-with-qml-and-javascript/
Item {

    property int period
    property var code

    Timer {
        id: timer
        repeat: true
        running: code && code.valid_to ? true : false
        interval: 250
        onTriggered: {
            var timeLeft = code.valid_to - Utils.getNow()
            var currentValue = timeLeft * (360 / period)
            root.arcEnd = 360 - currentValue
        }
    }

    id: root
    width: size
    height: size

    property int size: 12 // The size of the circle in pixel
    property real arcBegin: 0 // start arc angle in degree
    property real arcEnd: 0 // end arc angle in degree
    property bool isPie: true // paint a pie instead of an arc
    property bool showBackground: false // a full circle as a background of the arc
    property real lineWidth: 20 // width of the line
    property string colorCircle
    property string colorBackground

    property int animationDuration: 200

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

            if (root.isPie) {
                if (root.showBackground) {
                    ctx.beginPath()
                    ctx.fillStyle = root.colorBackground
                    ctx.moveTo(x, y)
                    ctx.arc(x, y, width / 2, 0, Math.PI * 2, false)
                    ctx.lineTo(x, y)
                    ctx.fill()
                }
                ctx.beginPath()
                ctx.fillStyle = root.colorCircle
                ctx.moveTo(x, y)
                ctx.arc(x, y, width / 2, start, end, false)
                ctx.lineTo(x, y)
                ctx.fill()
            } else {
                if (root.showBackground) {
                    ctx.beginPath()
                    ctx.arc(x, y, (width / 2) - parent.lineWidth / 2, 0,
                            Math.PI * 2, false)
                    ctx.lineWidth = root.lineWidth
                    ctx.strokeStyle = root.colorBackground
                    ctx.stroke()
                }
                ctx.beginPath()
                ctx.arc(x, y, (width / 2) - parent.lineWidth / 2, start,
                        end, false)
                ctx.lineWidth = root.lineWidth
                ctx.strokeStyle = root.colorCircle
                ctx.stroke()
            }
        }
    }
}
