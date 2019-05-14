import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Button {

    property alias toolTipText: buttonToolTip.text

    id: button
    font.capitalization: Font.MixedCase
    font.weight: Font.Medium
    font.pixelSize: 13
    Material.foreground: button.flat ? yubicoGreen : yubicoWhite
    Material.background: button.flat ? "transparent" : yubicoGreen
    Material.elevation: button.flat ? 0 : 1

    ToolTip {
        id: buttonToolTip
        text: ""
        delay: 1000
        parent: button
        visible: buttonToolTip.text.length > 0 && parent.hovered
        Material.foreground: app.isDark() ? defaultDarkForeground : defaultLight
        Material.background: app.isDark(
                                 ) ? defaultDarkOverlay : defaultLightForeground
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: false
    }
}
