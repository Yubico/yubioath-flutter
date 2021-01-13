import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ToolTip {

    property string message: "Default message"
    property string backgroundColor: yubicoGreen
    property int drawerWidth: drawer.visible ? drawer.width : 0

    id: tooltip
    timeout: 4000
    x: drawerWidth + (app.width - width) / 2
    y: app.height
    z: 2
    leftMargin: 8
    rightMargin: 8
    bottomMargin: 12
    height: 16 + (snackLbl.lineCount * 16)
    padding: 0
    background: Rectangle {
        color: backgroundColor
        radius: 30
        layer.enabled: true
        layer.effect: DropShadow {
            radius: 2
            samples: radius * 2
            verticalOffset: 1
            horizontalOffset: 0
            color: formHighlightItem
            transparentBorder: true
        }
    }

    RowLayout {
        spacing: 8
        anchors.fill: parent

        Label {
            id: snackLbl
            text: message
            color: fullContrast
            opacity: highEmphasis
            font.pixelSize: 13
            leftPadding: 8
            rightPadding: 8
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            horizontalAlignment: Qt.AlignHCenter
        }
    }
}
