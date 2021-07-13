import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {

    id: settingsPanel
    objectName: 'customReaderFlickable'
    contentWidth: app.width
    contentHeight: content.height + dynamicMargin

    onContentHeightChanged: {
        if (contentHeight > app.height - toolBar.height) {
             scrollBar.active = true
         }
    }

    Component.onCompleted: {
        yubiKey.refreshReaders()
    }

    ScrollBar.vertical: ScrollBar {
        id: scrollBar
        width: 8
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        hoverEnabled: true
        z: 2
    }
    boundsBehavior: Flickable.StopAtBounds

    property bool aboutToChange: customReaderCheckbox.checked !== settings.useCustomReader
                                 || readerFilter.text !== settings.customReaderName && readerFilter.text.length > 0

    function isValidMode() {
        return aboutToChange
    }

    function setInterface() {
        settings.useCustomReader = customReaderCheckbox.checked
        settings.customReaderName = readerFilter.text
        yubiKey.clearCurrentDeviceAndEntries()
        if (settings.useCustomReader) {
            yubiKey.loadDevicesCustomReaderOuter()
        } else {
            yubiKey.loadDevicesUsbOuter()
        }
        navigator.snackBar(qsTr("Interface changed"))
        navigator.pop()
    }

    ColumnLayout {
        id: content
        spacing: 0

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top

        width: app.width - dynamicMargin < dynamicWidth
               ? app.width - dynamicMargin
               : dynamicWidth

        Label {
            id: containerLabel
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            text: "Custom reader"
            color: Material.primary
            font.pixelSize: 16
            font.weight: Font.Normal
            topPadding: 24
            bottomPadding: 24
            Layout.fillWidth: true
        }

        Label {
            text: qsTr("Use an external smart card reader to interact with YubiKey, enable NFC capabilities or remote usage.")
            color: primaryColor
            opacity: lowEmphasis
            font.pixelSize: 13
            lineHeight: 1.2
            textFormat: TextEdit.PlainText
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
            Layout.bottomMargin: 16
        }

        Column {
            spacing: -8

            CheckBox {
                id: customReaderCheckbox
                checked: settings.useCustomReader
                text: qsTr("Enable custom reader")
                opacity: highEmphasis
                onCheckedChanged: {
                    if (checked) {
                        yubiKey.refreshReaders()
                    }
                }
            }
        }

        ColumnLayout {
            enabled: customReaderCheckbox.checked

            Label {
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                text: "Connected readers"
                opacity: lowEmphasis
                font.pixelSize: 12
                font.weight: Font.Normal
                topPadding: 16
                Layout.fillWidth: true
                visible: yubiKey.availableReaders.length > 0
            }

            ButtonGroup {
                id: radioButtons
                buttons: column.children
            }

            Column {
                id: column
                spacing: -8
                Layout.maximumWidth: content.width - 32

                Repeater {
                    model: yubiKey.availableReaders
                    RadioButton {
                        checked: index == 0 ? true : false
                        text: modelData
                        opacity: highEmphasis
                    }
                }
            }

            StyledButton {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                text: qsTr("Use as filter")
                enabled: yubiKey.availableReaders.length > 0 && radioButtons.checkedButton
                visible: yubiKey.availableReaders.length > 0
                onClicked: readerFilter.text = radioButtons.checkedButton.text
            }

            StyledTextField {
                id: readerFilter
                Layout.topMargin: 16
                labelText: qsTr("Custom reader filter")
                text: settings.customReaderName
            }
        }

        StyledButton {
            Layout.topMargin: 16
            Layout.alignment: Qt.AlignRight | Qt.AlignTop
            primary: true
            text: "Save"
            enabled: isValidMode()
            onClicked: setInterface()
        }
    }
}
