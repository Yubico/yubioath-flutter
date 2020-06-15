import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Controls.Material 2.2
import QtQuick.Controls.Material 2.4
import QtQuick.Controls.Material.impl 2.4
import QtQuick.Controls.impl 2.4
import QtQuick.Layouts 1.3
import QtQuick.Templates 2.4 as T

Button {
    id: button

    property alias toolTipText: buttonToolTip.text
    property bool critical: false
    property bool primary: false

    flat: false
    font.capitalization: Font.MixedCase
    font.weight: Font.Medium
    font.pixelSize: 13
    font.bold: false
    implicitHeight: 32
    leftPadding: 16
    rightPadding: 16
    Layout.minimumWidth: 66
    activeFocusOnTab: true
    focus: true
    Material.foreground: primary ? defaultBackground : (critical ? yubicoRed : Material.primary)

    Ripple {
        clipRadius: 2
        width: parent.width
        height: parent.height
        pressed: button.pressed
        anchor: button
        active: button.down || button.visualFocus || button.hovered
        color: button.Material.rippleColor
    }

    ToolTip {
        id: buttonToolTip

        text: ""
        delay: 1000
        parent: button
        visible: buttonToolTip.text.length > 0 && parent.hovered
        Material.foreground: toolTipForeground
        Material.background: toolTipBackground
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: false
    }

    background: Rectangle {
        color: primary ? (critical ? yubicoRed : Material.primary) : "transparent"
        opacity: parent.hovered ? highEmphasis : fullEmphasis
        border.color: formButtonBorder
        border.width: primary || flat ? 0 : 1
        radius: 4
        visible: !flat
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
    }

}
