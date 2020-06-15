import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3
import "utils.js" as Utils

// Heavily based on http://www.bytebau.com/progress-circle-with-qml-and-javascript/
Item {
    id: root

    property int period
    property int validTo
    property int size: 12
    property real arcBegin: 360
    property real arcEnd: 360

    signal timesUp()

    width: size
    height: size
    onArcBeginChanged: canvas.requestPaint()
    onArcEndChanged: canvas.requestPaint()

    Timer {
        id: timer

        repeat: true
        running: validTo > 0
        triggeredOnStart: true
        interval: 1000
        onTriggered: {
            var timeLeft = validTo - Utils.getNow();
            var currentValue = timeLeft * (360 / period);
            root.arcEnd = 360 - currentValue;
            if (timeLeft <= 0)
                timesUp();

        }
    }

    Canvas {
        id: canvas

        anchors.fill: parent
        rotation: -90
        onPaint: {
            var ctx = getContext("2d");
            var x = width / 2;
            var y = height / 2;
            var start = Math.PI * (parent.arcBegin / 180);
            var end = Math.PI * (parent.arcEnd / 180);
            ctx.reset();
            ctx.beginPath();
            ctx.fillStyle = primaryColor;
            ctx.globalAlpha = lowEmphasis;
            ctx.moveTo(x, y);
            ctx.arc(x, y, width / 2, end, start, false);
            ctx.lineTo(x, y);
            ctx.fill();
        }
    }

}
