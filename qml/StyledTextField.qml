import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0
import Qt.labs.platform 1.1

Item {

    property string label
    property alias echoMode: textField.echoMode
    property alias isEnabled: textField.enabled
    property alias text: textField.text
    property alias validator: textField.validator
    property alias horizontalAlignment: textField.horizontalAlignment
    property bool required: false
    property bool noedit: false
    property string labelText
    property string validateText
    property variant validateRegExp
    property alias textField: textField
    property bool error: false
    property bool isValidated: validateInput()
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
    height: 47
    implicitHeight: 47
    Layout.bottomMargin: 8
    Layout.fillWidth: true
    activeFocusOnTab: true

    onFocusChanged: {
        textField.forceActiveFocus()
    }

    function validateInput() {
        if (validateRegExp !== undefined) {
            if (textField.text.length) {
                if (!validateRegExp.test(textField.text))
                    return false
            }
        } else if (error) {
            if (textField.selectedText.length > 0) {
                return false
            } else {
                return true
            }
        }
        return true
    }

    function labelTextValue() {
        if (textField.activeFocus || textField.text.length > 0)
            return required ? labelText + " *" : labelText
        else {
            return " "
        }
    }

    Column {

        Label {
            font.pixelSize: 12
            color: isValidated ? (textField.activeFocus ? yubicoGreen : primaryColor) : yubicoRed
            opacity: enabled || noedit ? (isValidated && !textField.activeFocus ? lowEmphasis : fullEmphasis) : disabledEmphasis
            text: labelTextValue()
        }

        TextField {
            id: textField
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            selectByMouse: true
            selectedTextColor: fullContrast
            implicitWidth: textFieldContainer.width
            font.pixelSize: 13
            Keys.onEscapePressed: textField.focus = false
            Keys.onReturnPressed: {
                textField.focus = false
                textFieldContainer.submit()
            }
            Material.accent: isValidated ? yubicoGreen : yubicoRed
            Rectangle {
                color: {
                    if (parent.activeFocus) {
                        return isValidated ? yubicoGreen : yubicoRed
                    } else {
                        return parent.hovered ? formText : formUnderline
                    }
                }
                height: parent.hovered ? 2 : 1
                width: parent.width
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8
            }
            height: 41
            focus: true
            color: primaryColor
            opacity: enabled || noedit ? (selectedText.length > 0 ? fullEmphasis : highEmphasis) : disabledEmphasis
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
                    text: qsTr("Cut")
                    onTriggered: {
                        textField.cut()
                    }
                }
                MenuItem {
                    text: qsTr("Copy")
                    onTriggered: {
                        textField.copy()
                    }
                }
                MenuItem {
                    text: qsTr("Paste")
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
            visible: !isValidated
        }
    }
}
