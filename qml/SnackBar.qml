import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import QtQuick.Controls.Material 2.2

ToolTip {

    property string message: "Default message"

    timeout: 3000
    x: (app.width - width) / 2
    y: app.height
    width: snackLbl.implicitWidth + 40
    height: 40
    bottomMargin: 10

    Label {
        id: snackLbl
        text: message
        color: isDark() ? defaultDarkForeground : defaultLight
        font.pixelSize: 16
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
    }
}
