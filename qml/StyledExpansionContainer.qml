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

    property string sectionTitle

    Layout.alignment: Qt.AlignCenter | Qt.AlignTop
    Layout.fillWidth: true
    Layout.maximumWidth: dynamicWidth + dynamicMargin
    spacing: 0
    Layout.margins: 0
    visible: {
        if (toolBar.searchField.text.length > 0) {
            for (var i = 0; i < children.length; ++i) {
                if (!!children[i] && children[i].toString().startsWith("StyledExpansionPanel") && children[i].visible) {
                    return true
                }
            }
            return false
        }
        return true
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        width: app.width - dynamicMargin < dynamicWidth ? app.width - dynamicMargin : dynamicWidth
        spacing: 8

        RowLayout {
            Label {
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                text: sectionTitle
                color: Material.primary
                font.pixelSize: 14
                font.weight: Font.Medium
                topPadding: 8
                bottomPadding: 8
                Layout.fillWidth: true
            }
        }

        id: inner_space
    }
}
