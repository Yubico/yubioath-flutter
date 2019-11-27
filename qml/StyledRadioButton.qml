import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Item {

    property alias text: controlItem.text
    property alias description: controlDescription.text
    property alias enabled: control.enabled
    property alias objectName: control.objectName
    property alias checked: control.checked
    property var buttonGroup

    height: 40
    Layout.bottomMargin: 8

    RowLayout {

        RadioButton {
            id: control
            ButtonGroup.group: buttonGroup
            indicator.x: 8

            contentItem: ColumnLayout {

                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                Label {
                    id: controlItem
                    leftPadding: control.indicator.width + control.spacing + control.x
                    color: primaryColor
                    opacity: control.enabled ? highEmphasis : disabledEmphasis
                }

                Label {
                    id: controlDescription
                    leftPadding: control.indicator.width + control.spacing + control.x
                    color: primaryColor
                    opacity: control.enabled ? lowEmphasis : disabledEmphasis
                    visible: description
                }
            }
        }
    }
}
