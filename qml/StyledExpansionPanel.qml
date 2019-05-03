import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ColumnLayout {

    id: expansionPanel

    property string label
    property string description
    property bool isExpanded: false

    RowLayout {

        ColumnLayout {
            Label {
                text: label
                font.pixelSize: 13
                font.bold: false
                color: formText
                Layout.fillWidth: true
            }
            Label {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.fillWidth: true
                font.pixelSize: 11
                font.italic: true
                color: formLabel
                text: description
                wrapMode: Text.WordWrap
                Layout.rowSpan: 1
            }
        }

        ToolButton {
            onClicked: isExpanded ? isExpanded = false : isExpanded = true
            icon.width: 24
            icon.source: isExpanded ? "../images/up.svg" : "../images/down.svg"
            icon.color: isDark() ? yubicoWhite : yubicoGrey
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: false
            }
        }
    }
}
