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
    property string keyImage
    property string backgroundColor: defaultElevated

    property bool isEnabled: true
    property bool isExpanded: false
    property bool isTopPanel: false
    property bool isBottomPanel: false
    property bool isSectionTitle: false
    property bool dropShadow: true

    property string toolButtonIcon
    property string toolButtonToolTip
    property alias toolButton: toolButton
    property alias expandedContent: expandedContent

    Layout.alignment: Qt.AlignCenter | Qt.AlignTop
    Layout.fillWidth: true
    Layout.maximumWidth: dynamicWidth + dynamicMargin

    Layout.leftMargin: -16
    Layout.rightMargin: -16

    Layout.topMargin: isExpanded && dropShadow && !isTopPanel ? 9 : -4
    Layout.bottomMargin: isExpanded && dropShadow && !isBottomPanel ? 11 : -3

    Material.background: backgroundColor
    Material.elevation: dropShadow ? 1 : 0

    function expandAction() {
        function collapseAll() {
            for (var i = 0; i < parent.children.length; ++i) {
                if (!!parent.children[i] &&
                        parent.children[i].toString().indexOf("StyledExpansionPanel") === 0) {
                    parent.children[i].isExpanded = false
                }
            }
        }

        if (isEnabled) {
            if (isExpanded) {
                isExpanded = false
            } else {
                collapseAll()
                isExpanded = true
            }
        }
    }

    ColumnLayout {

        anchors.horizontalCenter: parent.horizontalCenter
        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
        width: parent.width - dynamicMargin < dynamicWidth ? parent.width - dynamicMargin : dynamicWidth
        spacing: 16

        RowLayout {
            Layout.leftMargin: -12
            Layout.rightMargin: -24

            Rectangle {
                id: rectangle
                width: 40
                height: 40
                color: formHighlightItem
                radius: width * 0.5
                visible: keyImage
                Layout.rightMargin: 8
                Image {
                    id: key
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    sourceSize.width: 32
                    source: keyImage
                    fillMode: Image.PreserveAspectFit
                    visible: keyImage && !!yubiKey.currentDevice
                }
                StyledImage {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    iconWidth: 21
                    iconHeight: 23
                    source: keyImage
                    visible: keyImage && !key.visible
                    color: formImageOverlay
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                visible: label

                Label {
                    visible: isSectionTitle
                    Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    text: label
                    color: Material.primary
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                }

                Label {
                    visible: !isSectionTitle
                    text: label
                    font.pixelSize: 13
                    font.bold: false
                    color: primaryColor
                    opacity: highEmphasis
                    Layout.fillWidth: true
                }
                Label {
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                    Layout.fillWidth: true
                    font.pixelSize: 13
                    color: primaryColor
                    opacity: lowEmphasis
                    text: description
                    wrapMode: Text.WordWrap
                    maximumLineCount: isExpanded ? 4 : 2
                    elide: Text.ElideRight
                    lineHeight: 1.1
                    visible: description
                }
            }

            ToolButton {
                id: expandButton
                onClicked: expandAction()
                icon.width: 24
                icon.source: isExpanded ? "../images/up.svg" : "../images/down.svg"
                icon.color: primaryColor
                opacity: hovered ? fullEmphasis : lowEmphasis
                visible: isEnabled
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: false
                }
                ToolTip {
                    text: isExpanded ? qsTr("Show less") : qsTr("Show more")
                    delay: 1000
                    parent: expandButton
                    visible: parent.hovered
                    Material.foreground: toolTipForeground
                    Material.background: toolTipBackground
                }
            }

            ToolButton {
                id: toolButton
                icon.width: 24
                icon.source: toolButtonIcon
                icon.color: primaryColor
                opacity: hovered ? fullEmphasis : lowEmphasis
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
                    Material.foreground: toolTipForeground
                    Material.background: toolTipBackground
                }
            }
        }

        RowLayout {
            id: expandedContent
            visible: isExpanded
            Layout.leftMargin: -12
            Layout.rightMargin: -12
            ColumnLayout {
                id: inner_space
            }
        }
    }
}
