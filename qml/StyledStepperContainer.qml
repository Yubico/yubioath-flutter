import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Pane {
    id: stepperContainer

    default property alias children: inner_space.data

    readonly property int dynamicWidth: 648
    readonly property int dynamicMargin: 32

    property int initialStep: 1

    Layout.alignment: Qt.AlignCenter | Qt.AlignTop
    Layout.fillWidth: true
    Layout.maximumWidth: dynamicWidth + dynamicMargin
    spacing: 0
    Layout.margins: 0
    Layout.leftMargin: -8

    background: Rectangle {
        color: "transparent"
    }

    function initSteps(currentStep) {
        var counter = 0
        for (var i = 0; i < children.length; ++i) {
            if (!!children[i]
                    && children[i].toString().indexOf("StyledStepperPanel") === 0) {
                counter++

                children[i].step = counter

                if (counter < currentStep) {
                    children[i].isCompleted = true
                    children[i].isExpanded = false
                } else if (counter > currentStep) {
                    children[i].isCompleted = false
                    children[i].isExpanded = false
                } else {
                    children[i].isCompleted = false
                    children[i].isExpanded = true
                }

                if (i === children.length - 1) {
                    children[i].isFinalStep = true
                }
            }
        }
    }

    Component.onCompleted: initSteps(initialStep)

    ColumnLayout {
        width: app.width - dynamicMargin < dynamicWidth ? app.width - dynamicMargin : dynamicWidth

        id: inner_space

    }
}
