import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Button {

    property alias toolTipText: buttonToolTip.text
    property bool critical: false

    id: button
    font.capitalization: Font.capitalization
    font.weight: Font.Medium
    Material.foreground: button.flat ? (critical ? yubicoRed : Material.primary) : yubicoWhite
    Material.background: button.flat ? "transparent" : (critical ? yubicoRed : Material.primary)
    Material.elevation: button.flat ? 0 : 1

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
}
