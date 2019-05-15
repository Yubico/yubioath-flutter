import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Pane {

    id: expansionPanel

    default property alias children: inner_space.data

    readonly property int dynamicWidth: 864
    readonly property int dynamicMargin: 32

    property string label
    property string description
    property bool isEnabled: true
    property bool isExpanded: false
    property bool isTopPanel: false
    property bool isBottomPanel: false
    property bool dropShadow: true

    property string toolButtonIcon
    property string toolButtonToolTip
    property alias toolButton: toolButton

    property var motherView

    Layout.alignment: Qt.AlignCenter | Qt.AlignTop
    Layout.fillWidth: true
    Layout.maximumWidth: dynamicWidth + dynamicMargin

    Layout.leftMargin: -16
    Layout.rightMargin: -16
    Layout.topMargin: isExpanded && !isTopPanel ? 9 : -4
    Layout.bottomMargin: isExpanded && !isBottomPanel ? 11 : -3

    background: Rectangle {
        color: isDark() ? defaultDarkLighter : defaultLightDarker
        layer.enabled: dropShadow
        layer.effect: DropShadow {
            radius: 4
            samples: radius * 2
            verticalOffset: 2
            horizontalOffset: 2
            color: formDropShdaow
            transparentBorder: true
        }
    }

    function expandAction() {
        if (isEnabled) {
            if (isExpanded) {
                motherView.contentHeight = motherView.contentHeight - expansionPanel.height
                isExpanded = false
            } else {
                isExpanded = true
                motherView.contentHeight = motherView.contentHeight + expansionPanel.height
            }
        }
    }

    ColumnLayout {

        anchors.horizontalCenter: parent.horizontalCenter
        width: app.width - dynamicMargin < dynamicWidth ? app.width - dynamicMargin : dynamicWidth
        spacing: 16

        RowLayout {
            Layout.rightMargin: -12

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true

                Label {
                    text: label
                    font.pixelSize: 13
                    font.bold: false
                    color: formText
                    Layout.fillWidth: true
                }
                Label {
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                    Layout.fillWidth: true
                    font.pixelSize: 11
                    color: formLabel
                    text: description
                    wrapMode: Text.WordWrap
                    Layout.rowSpan: 1
                }
            }

            ToolButton {
                id: expandButton
                onClicked: expandAction()
                icon.width: 24
                icon.source: isExpanded ? "../images/up.svg" : "../images/down.svg"
                icon.color: isDark() ? yubicoWhite : yubicoGrey
                visible: isEnabled
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: false
                }
                ToolTip {
                    text: isExpanded ? "Show less" : "Show more"
                    delay: 1000
                    parent: expandButton
                    visible: parent.hovered
                    Material.foreground: app.isDark(
                                             ) ? defaultDarkForeground : defaultLight
                    Material.background: app.isDark(
                                             ) ? defaultDarkOverlay : defaultLightForeground
                }
            }

            ToolButton {
                id: toolButton
                icon.width: 24
                icon.source: toolButtonIcon
                icon.color: isDark() ? yubicoWhite : yubicoGrey
                visible: !isEnabled && !!toolButtonIcon
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: false
                }
                ToolTip {
                    text: toolButtonToolTip
                    delay: 1000
                    parent: toolButton
                    visible: parent.hovered
                    Material.foreground: app.isDark(
                                             ) ? defaultDarkForeground : defaultLight
                    Material.background: app.isDark(
                                             ) ? defaultDarkOverlay : defaultLightForeground
                }
            }
        }

        RowLayout {
            visible: isExpanded
            ColumnLayout {
                id: inner_space
            }
        }
    }
}
