import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {

    id: settingsPanel
    objectName: 'customReaderFlickable'
    width: app.width
    contentWidth: app.width
    contentHeight: expandedHeight

    property var expandedHeight: content.implicitHeight + dynamicMargin

    onExpandedHeightChanged: {
        if (expandedHeight > app.height - toolBar.height) {
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
            //settings.otpMode = false
            yubiKey.loadDevicesCustomReaderOuter()
        } else {
            yubiKey.loadDevicesUsbOuter()
        }
        navigator.snackBar(qsTr("Interface changed"))
        navigator.pop()
    }

    ColumnLayout {
        id: content
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - dynamicMargin
        Layout.leftMargin: dynamicMarginSmall
        Layout.rightMargin: dynamicMarginSmall
        spacing: 0

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
            id: panelDescription
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.fillWidth: true
            font.pixelSize: 13
            color: primaryColor
            opacity: lowEmphasis
            text: qsTr("Use an external smart card reader to interact with YubiKey, enable NFC capabilities or remote usage.")
            textFormat: TextEdit.PlainText
            wrapMode: Text.WordWrap
            maximumLineCount: 4
            elide: Text.ElideRight
            bottomPadding: 16
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

                Repeater {
                    model: yubiKey.availableReaders
                    RadioButton {
                        checked: index == 0 ? true : false
                        text: modelData
                        opacity: highEmphasis
                        implicitWidth: app.width - dynamicMargin
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
            text: "Apply"
            enabled: isValidMode()
            onClicked: setInterface()
        }
    }
}
