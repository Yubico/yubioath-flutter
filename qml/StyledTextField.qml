import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0
import Qt.labs.platform 1.1

Item {

    property string label
    property alias echoMode: textField.echoMode
    property alias text: textField.text
    property alias validator: textField.validator
    property alias horizontalAlignment: textField.horizontalAlignment
    property bool required: false
    property string labelText
    property string validateText
    property variant validateRegExp
    property alias textField: textField
    property bool validated: {
        if (validateInput()) {
            if (required && textField.text.length > 0) {
                return true
            } else if (!required) {
                return true
            }
        }
        return false
    }
    signal submit()

    id: textFieldContainer
    height: 50
    implicitHeight: 50
    Layout.bottomMargin: 8
    Layout.fillWidth: true

    function validateInput() {
        if (validateRegExp !== undefined) {
            if (textField.text.length) {
                if (!validateRegExp.test(textField.text))
                    return false
            }
        }
        return true
    }

    function labelTextValue() {
        if (!validateInput()) {
            return "Error"
        } else if (textField.activeFocus || textField.text.length > 0)
            return required ? labelText + " *" : labelText
        else {
            return " "
        }
    }

    Column {

        Label {
            font.pixelSize: 10
            color: validateInput() ? formLabel : yubicoRed
            text: labelTextValue()
        }

        TextField {
            id: textField
            Layout.topMargin: 10
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            selectByMouse: true
            implicitWidth: textFieldContainer.width
            font.pixelSize: 13
            Keys.onEscapePressed: textField.focus = false
            Keys.onReturnPressed: {
                textField.focus = false
                textFieldContainer.submit()
            }
            Material.accent: validateInput() ? yubicoGreen : yubicoRed
            height: 40
            activeFocusOnTab: true
            focus: true
            color: formText
            placeholderText: {
                if (textField.activeFocus) {
                    return ""
                } else {
                    return required ? labelText + " *" : labelText
                }
            }
            placeholderTextColor: formPlaceholderText

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                hoverEnabled: true
                cursorShape: Qt.IBeamCursor
                onClicked: {
                    contextMenu.open();
                }
                onPressAndHold: {
                    if (mouse.source === Qt.MouseEventNotSynthesized) {
                        contextMenu.open();
                    }
                }
            }

            Menu {
                id: contextMenu

                MenuItem {
                    text: "Cut"
                    onTriggered: {
                        textField.cut()
                    }
                }
                MenuItem {
                    text: "Copy"
                    onTriggered: {
                        textField.copy()
                    }
                }
                MenuItem {
                    text: "Paste"
                    onTriggered: {
                        textField.paste()
                    }
                }
            }

        }

        Label {
            font.pixelSize: 10
            color: yubicoRed
            text: validateText
            visible: !validateInput()
        }
    }
}
