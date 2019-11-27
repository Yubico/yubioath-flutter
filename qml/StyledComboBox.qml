import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Item {

    property string label
    property string selectedValue
    property alias comboBox: comboBox
    property alias model: comboBox.model
    property alias currentIndex: comboBox.currentIndex
    property alias currentText: comboBox.currentText
    property alias displayText: comboBox.displayText

    id: container
    height: 47
    implicitHeight: 47
    Layout.bottomMargin: 8
    Layout.fillWidth: true

    Column {

        Label {
            text: label
            font.pixelSize: 12
            color: primaryColor
            opacity: lowEmphasis
        }

        ComboBox {
            id: comboBox
            Layout.fillWidth: true
            implicitWidth: container.width
            font.pixelSize: 13
            flat: true
            indicator: Rectangle {
                id: rectangle
                anchors.right: parent.right
                anchors.rightMargin: -8
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                width: 32
                StyledImage {
                    id: arrowIcon
                    source: "../images/arrow-down.svg"
                    iconWidth: 24
                    iconHeight: 24
                    color: primaryColor
                    opacity: highEmphasis
                }
            }
            contentItem: Text {
                color: primaryColor
                opacity: highEmphasis
                font.pixelSize: 13
                text: parent.displayText
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
            }
            currentIndex: {
                if (selectedValue && selectedValue.length > 0) {
                    return model.findIndex(function(element) {
                      return element === selectedValue
                    });
                }
                else {
                    return 0
                }
            }
            background: Rectangle {
                color: "transparent"
                implicitHeight: 20
            }
        }

        Pane {
            height: 2
            Layout.fillWidth: true
            background: Rectangle {
                color: comboBox.hovered ? formText : formUnderline
                height: comboBox.hovered ? 2 : 1
                implicitWidth: comboBox.width
            }
        }
    }
}
