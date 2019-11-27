import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Pane {

    id: stepperPanel

    default property alias children: inner_space.data

    readonly property int dynamicWidth: 864
    readonly property int dynamicMargin: 32

    property int step: 0

    property string label
    property string description
    property string keyImage

    property bool isFinalStep: false
    property bool isCompleted: false
    property bool isEnabled: true
    property bool isExpanded: false

    property string toolButtonIcon
    property string toolButtonToolTip
    property alias expandedContent: expandedContent
    property alias circle: circle

    Layout.alignment: Qt.AlignCenter | Qt.AlignTop
    Layout.fillWidth: true
    Layout.maximumWidth: dynamicWidth + dynamicMargin

    Layout.leftMargin: -16
    Layout.rightMargin: -16

    background: Rectangle {
        color: "transparent"
        MouseArea {
            onClicked: expandAction(step)
            width: parent.width
            height: parent.height < 74 ? parent.height : 74
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            enabled: !isExpanded
        }

    }

    function expandAction() {
        var counter = 0
        for (var i = 0; i < parent.children.length; ++i) {
            if (!!parent.children[i] &&
                    parent.children[i].toString().indexOf("StyledStepperPanel") === 0) {
                counter++

                if (counter < step) {
                    parent.children[i].isCompleted = true
                    parent.children[i].isExpanded = false
                } else if (counter > step) {
                    parent.children[i].isCompleted = false
                    parent.children[i].isExpanded = false
                } else {
                    parent.children[i].isCompleted = false
                    parent.children[i].isExpanded = true
                }
            }
        }
    }

    onIsExpandedChanged: {
        canvas.requestPaint()
    }

    ColumnLayout {

        anchors.horizontalCenter: parent.horizontalCenter
        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
        width: app.width - dynamicMargin < dynamicWidth ? app.width - dynamicMargin : dynamicWidth
        spacing: 16

        RowLayout {
            Layout.rightMargin: -12

            Rectangle {
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                id: circle
                width: 20
                height: 20
                color: isExpanded || isCompleted ? yubicoGreen : formStepBackground
                radius: width * 0.5
                Layout.rightMargin: 8
                Image {
                    anchors.fill: parent
                    id: check
                    source: "../images/check.svg"
                    visible: isCompleted
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                }
                ColorOverlay {
                        anchors.fill: check
                        visible: isCompleted
                        source: check
                        color: yubicoWhite
                }
                Label {
                    anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter; }
                    text: step
                    visible: !isCompleted
                    font.pixelSize: 13
                    color: yubicoWhite
                }


            Canvas {
                id: canvas
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                Layout.fillWidth: true
                Layout.fillHeight: true
                width: 20
                height: stepperPanel.height
                visible: !isFinalStep || (isFinalStep && isExpanded)
                onPaint: {
                    var context = getContext("2d");
                    context.beginPath();
                    context.lineWidth = 1;
                    context.moveTo(width / 2, circle.height + 5);
                    context.strokeStyle = formHighlightItem
                    context.lineTo(width / 2, height);
                    context.stroke();
                    }
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                Layout.topMargin: 3
                visible: label

                Label {
                    Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    text: label
                    font.pixelSize: 13
                    font.weight: isExpanded ? Font.Medium : Font.Normal
                    color: primaryColor
                    opacity: highEmphasis
                    Layout.fillWidth: true
                }
                Label {
                    Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    Layout.fillWidth: true
                    font.pixelSize: 13
                    color: primaryColor
                    opacity: lowEmphasis
                    text: description
                    wrapMode: Text.WordWrap
                    Layout.rowSpan: 1
                    lineHeight: 1.1
                    visible: isExpanded && description
                }

                RowLayout {
                    id: expandedContent
                    visible: isExpanded
                    Layout.rightMargin: 32
                    ColumnLayout {
                        id: inner_space
                    }
                }
            }            
        }
    }
}
