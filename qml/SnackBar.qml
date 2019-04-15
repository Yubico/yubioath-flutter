import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ToolTip {

    property string message: "Default message"
    property string buttonText: "Dismiss"
    property string buttonColor: yubicoGreen

    timeout: 5000
    x: (app.width - width) / 2
    y: app.height
    width: 300
    height: 48
    bottomMargin: 10
    padding: 0
    background: Rectangle {
        color: "#333333"
        radius: 4
    }

    Item {
        anchors.fill: parent

        Label {
            id: snackLbl
            text: message
            anchors.verticalCenterOffset: 0
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            color: isDark() ? defaultDarkForeground : defaultLight
            opacity: 0.87
            font.pixelSize: 13
            leftPadding: 0
            rightPadding: 8
        }

        StyledButton {
            id: snackBtn
            flat: true
            text: buttonText
            Material.foreground: buttonColor
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 0
        }
    }
}
