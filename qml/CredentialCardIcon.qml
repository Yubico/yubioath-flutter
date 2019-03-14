import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2

Rectangle {

    property string letter: "A"
    property int size: 60
    width: size
    height: size
    radius: width * 0.5
    color: Material.accent

    Label {
        text: letter.toUpperCase()
        font.pixelSize: 32
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        color: yubicoWhite
    }
}
