import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import Qt.labs.settings 1.0
import QtQuick.Window 2.2
import QtQml 2.12

Pane {
    id: item
    hoverEnabled: true
    Layout.topMargin: 4
    Layout.bottomMargin: 4
    topPadding: 0
    bottomPadding: 0
    spacing: 0
    implicitWidth: drawer.width - 16
    Layout.leftMargin: 8
    height: content.implicitHeight

    property alias icon: image.source
    property alias text: label.text
    property bool isActive: false
    property bool isEnabled: true
    property bool isHovered: false

    signal activated(bool clicked)

    background: Rectangle {
        anchors.fill: parent
        color: item.isActive ? yubicoGreen : (item.hovered || isHovered ? defaultHovered : "transparent")
        radius: 4
        MouseArea {
            id: itemMouseArea
            enabled: !isActive && isEnabled
            hoverEnabled: !isActive && isEnabled
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: !isEnabled || isActive ? Qt.ArrowCursor : Qt.PointingHandCursor
            onClicked: {
                if(isEnabled && !isActive) {
                    activated(true);
                    drawer.visible = false
                }
            }
        }
    }

    RowLayout {
        id: content
        spacing: 0
        StyledImage {
            id: image
            iconHeight: 20
            Layout.leftMargin: -16
            topInset: 0
            bottomInset: 0
            color: item.isActive ? defaultBackground : primaryColor
            opacity: isEnabled ? (((item.hovered || isHovered) && !item.isActive) || isActive ? highEmphasis : lowEmphasis) : disabledEmphasis
        }
        Label {
            Layout.leftMargin: 0
            id: label
            font.pixelSize: 13
            font.weight: Font.Medium
            color: image.color
            opacity: image.opacity
            elide: Text.ElideRight
            Layout.maximumWidth: 120
        }
    }
}
