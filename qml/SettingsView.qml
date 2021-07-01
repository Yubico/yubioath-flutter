import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {

    id: settingsPanel
    objectName: 'settingsView'
    contentWidth: app.width
    contentHeight: expandedHeight

    property var expandedHeight: content.implicitHeight + dynamicMargin

    onExpandedHeightChanged: {
        if (expandedHeight > app.height - toolBar.height) {
             scrollBar.active = true
         }
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

    property string searchFieldPlaceholder: ""

    ColumnLayout {
        width: settingsPanel.contentWidth
        id: content
        spacing: 0

        ColumnLayout {
            Layout.leftMargin: 16
            Layout.rightMargin: 16

            Label {
                id: containerLabel
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                text: "Settings"
                color: Material.primary
                font.pixelSize: 16
                font.weight: Font.Normal
                topPadding: 24
                bottomPadding: 8
                Layout.fillWidth: true
            }

            Label {
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                text: "Appearance"
                opacity: lowEmphasis
                font.pixelSize: 12
                font.weight: Font.Normal
                topPadding: 16
                Layout.fillWidth: true
            }

            ButtonGroup {
                buttons: column.children
                onCheckedButtonChanged: {
                    switch (checkedButton) {
                    case radioBtnDefault:
                        if (settings.theme !== Material.System) {
                            settings.theme = Material.System
                        }
                        return
                    case radioBtnLight:
                        if (settings.theme !== Material.Light) {
                            settings.theme = Material.Light
                        }
                        return
                    case radioBtnDark:
                        if (settings.theme !== Material.Dark) {
                            settings.theme = Material.Dark
                        }
                        return
                    }
                }
            }

            Column {
                id: column
                spacing: -8

                RadioButton {
                    id: radioBtnDefault
                    text: qsTr("System default")
                    opacity: highEmphasis
                    checked: settings.theme === Material.System
                }

                RadioButton {
                    id: radioBtnLight
                    text: qsTr("Light mode")
                    opacity: highEmphasis
                    checked: settings.theme === Material.Light
                }

                RadioButton {
                    id: radioBtnDark
                    text: qsTr("Dark mode")
                    opacity: highEmphasis
                    checked: settings.theme === Material.Dark
                }
            }

            Label {
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                text: "Application"
                opacity: lowEmphasis
                font.pixelSize: 12
                font.weight: Font.Normal
                topPadding: 16
                Layout.fillWidth: true
            }

            Column {
                spacing: -8

                CheckBox {
                    id: sysTrayCheckbox
                    checked: settings.closeToTray
                    text: Qt.platform.os === "osx" ? qsTr("Show in menu bar") : qsTr("Show in system tray")
                    opacity: highEmphasis
                    onCheckStateChanged: {
                        if(!checked) {
                            hideOnLaunchCheckbox.checked = false
                        }
                        settings.closeToTray = checked
                    }
                }

                CheckBox {
                    id: hideOnLaunchCheckbox
                    enabled: sysTrayCheckbox.checked
                    checked: settings.hideOnLaunch
                    text: qsTr("Hide on launch")
                    opacity: highEmphasis
                    onCheckStateChanged: settings.hideOnLaunch = checked
                }
            }

            Label {
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                text: "Advanced"
                opacity: lowEmphasis
                font.pixelSize: 12
                font.weight: Font.Normal
                topPadding: 16
                Layout.fillWidth: true
                visible: customReaderPanel.visible || savedPasswordsPanel.visible
            }
        }

        StyledExpansionContainer {
            StyledExpansionPanel {
                id: customReaderPanel
                label: qsTr("Custom reader")
                enabled: !settings.otpMode
                description: qsTr("Use an external smart card reader to interact with YubiKey, enable NFC capabilities or remote usage.")
                metadata: "ccid otp slot custom readers nfc"
                isFlickable: true
                expandButton.onClicked: navigator.goToCustomReader()
            }

            StyledExpansionPanel {
                id: savedPasswordsPanel
                label: qsTr("Saved passwords")
                isEnabled: false
                isBottomPanel: true
                actionButton.text: "Clear"
                actionButton.onClicked: navigator.confirm({
                        "heading": qsTr("Clear passwords?"),
                        "message": qsTr("This will delete all saved passwords."),
                        "description": qsTr("A password prompt will appear the next time a YubiKey with a password is used."),
                        "buttonAccept": qsTr("Clear passwords"),
                        "acceptedCb": function() {
                            yubiKey.clearLocalPasswords(function (resp) {
                            if (resp.success) {
                                navigator.snackBar(qsTr("Passwords cleared"))
                            }
                    })}
                })
            }

        }
    }
}
