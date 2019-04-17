import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Item {

    property string label
    property alias comboBox: comboBox
    property alias model: comboBox.model
    property alias currentIndex: comboBox.currentIndex
    property alias currentText: comboBox.currentText

    id: container
    height: 50
    implicitHeight: 50
    Layout.fillWidth: true

    Column {

        Label {
            text: label
            font.pixelSize: 10
            color: yubicoGrey
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
                anchors.rightMargin: 0
                Image {
                    id: arrowIcon
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    fillMode: Image.PreserveAspectFit
                    source: "../images/arrow-down.svg"
                    ColorOverlay {
                        source: arrowIcon
                        color: isDark() ? defaultLight : yubicoGrey
                        anchors.fill: arrowIcon
                    }
                }
            }
            contentItem: Text {
                color: isDark() ? defaultDarkForeground : defaultLightForeground
                text: parent.displayText
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
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
                color: isDark() ? yubicoWhite : yubicoGrey
                height: comboBox.hovered ? 2 : 1
                implicitWidth: comboBox.width
            }
        }
    }
}
