import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Button {
    id: button
    flat: true
    hoverEnabled: true
    font.capitalization: Font.MixedCase
    font.bold: false
    font.pointSize: 13
    Material.foreground: yubicoWhite
    implicitHeight: 44
    leftPadding: 12
    rightPadding: 12
    background: Rectangle {
        radius: 2
        color: yubicoGreen
        opacity: parent.hovered ? 0.9 : 1
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: false
    }
}
