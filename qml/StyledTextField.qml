import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

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

    function underLineColor() {
        if (!validateInput()) {
            return yubicoRed
        } else if (textField.activeFocus) {
            return formLabel
        } else {
            return formUnderline
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
            selectedTextColor: isDark() ? defaultDark : defaultLight
            Keys.onEscapePressed: textField.focus = false
            height: 40
            activeFocusOnTab: true
            focus: true
            color: formText
            Material.accent: formText
            placeholderText: {
                if (textField.activeFocus) {
                    return ""
                } else {
                    return required ? labelText + " *" : labelText
                }
            }
            placeholderTextColor: formPlaceholderText
            background: Item {
                implicitWidth: parent.width
                implicitHeight: 40
                Rectangle {
                    color: underLineColor()
                    height: textField.hovered || textField.activeFocus ? 2 : 1
                    width: parent.width
                    y: 32
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
