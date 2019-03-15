import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2

Rectangle {

    property string letter: "A"
    property int size: 40
    width: size
    height: size
    radius: width * 0.5
    color: yubicoGreen

    Label {
        text: letter.toUpperCase()
        font.bold: true
        font.pixelSize: 24
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        color: yubicoWhite
    }
}
