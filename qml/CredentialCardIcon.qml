import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2

Rectangle {

    property string letter: "A"
    property int size: 40
    width: size
    height: size
    radius: width * 0.5
    color: Material.primary
    Label {
        text: letter.toUpperCase()
        font.bold: true
        font.pixelSize: Qt.application.font.pixelSize * 1.8
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        color: yubicoWhite
    }
}
