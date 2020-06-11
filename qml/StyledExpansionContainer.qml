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

    Layout.fillWidth: true
    Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
    spacing: 0
    topPadding: 0
    bottomPadding: 0
    Layout.topMargin: 4
    Layout.bottomMargin: 4
    Layout.leftMargin: app.width > dynamicWidth ? 16 : 0
    Layout.rightMargin: app.width > dynamicWidth ? 16 : 0

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
                font.pixelSize: 16
                font.weight: Font.Normal
                topPadding: 24
                bottomPadding: 8
                Layout.fillWidth: true
            }
        }

        id: inner_space
    }
}
