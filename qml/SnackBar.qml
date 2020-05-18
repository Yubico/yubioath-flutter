import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ToolTip {

    property string message: "Default message"
    property string buttonText: "Dismiss"
    property string buttonColor: Material.primary
    property string backgroundColor: "#333333"
    property bool fullWidth: false
    readonly property int dynamicWidth: 640
    readonly property int dynamicMargin: 16

    id: tooltip
    timeout: 3000
    x: (app.width - width) / 2
    y: app.height
    z: 2
    width: fullWidth ? app.width : app.width - dynamicMargin
                       < dynamicWidth ? app.width - dynamicMargin : dynamicWidth
    leftMargin: fullWidth ? 0 : 8
    rightMargin: fullWidth ? 0 : 8
    bottomMargin: fullWidth ? 0 : 8
    height: 48
    padding: 0
    background: Rectangle {
        color: primaryColor
        radius: fullWidth ? 0 : 4
        layer.enabled: !fullWidth
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
            color: defaultElevated
            opacity: highEmphasis
            font.pixelSize: 13
            leftPadding: 8
            rightPadding: 0
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        StyledButton {
            id: snackBtn
            flat: true
            text: buttonText
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Material.foreground: buttonColor
            onClicked: tooltip.close()
        }
    }
}
