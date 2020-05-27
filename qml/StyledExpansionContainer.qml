import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Pane {
    id: expansionContainer

    default property alias children: inner_space.data

    readonly property int dynamicWidth: 648
    readonly property int dynamicMargin: 32

    property string title

    Layout.alignment: Qt.AlignCenter | Qt.AlignTop
    Layout.fillWidth: true
    Layout.maximumWidth: dynamicWidth + dynamicMargin
    spacing: 0
    topPadding: 0
    bottomPadding: 0

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        spacing: 8

        RowLayout {
            Label {
                id: containerLabel
                visible: inner_space.visibleChildren.length > 1
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                text: title
                color: Material.primary
                font.pixelSize: 14
                font.weight: Font.Medium
                topPadding: 24
                bottomPadding: 8
                Layout.fillWidth: true
            }
        }

        id: inner_space
    }
}
