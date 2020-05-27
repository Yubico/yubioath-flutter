import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {

    readonly property int dynamicWidth: 648
    readonly property int dynamicMargin: 32

    id: enterPasswordViewId
    objectName: 'enterPasswordView'
    property string title: ""

    ScrollBar.vertical: ScrollBar {
        width: 8
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        hoverEnabled: true
        z: 2
    }
    boundsBehavior: Flickable.StopAtBounds

    contentWidth: app.width

    function clear() {
        passwordField.text = ""
        rememberPasswordCheckBox.checked = false
    }

    function validate() {
        if (passwordField.text.valueOf().length > 0) {
            yubiKey.validate(passwordField.text,
                             rememberPasswordCheckBox.checked, function (resp) {
                                 if (resp.success) {
                                     yubiKey.currentDeviceValidated = true
                                     yubiKey.calculateAll(navigator.goToCredentials)
                                 } else {
                                     clear()
                                     navigator.snackBarError(
                                                 navigator.getErrorMessage(
                                                     resp.error_id))
                                     console.log("validate failed:",
                                                 resp.error_id)
                                     passwordField.textField.forceActiveFocus()
                                 }
                             })
        }
    }

    Component.onCompleted: {
        passwordField.textField.forceActiveFocus()
    }

    ColumnLayout {
        id: content

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        spacing: 4
        width: app.width - dynamicMargin
               < dynamicWidth ? app.width - dynamicMargin : dynamicWidth

        Label {
            text: "Unlock YubiKey"
            font.pixelSize: 16
            font.weight: Font.Normal
            lineHeight: 1.8
            color: yubicoGreen
            opacity: fullEmphasis
            Layout.topMargin: 16
        }

        StyledTextField {
            id: passwordField
            labelText: qsTr("Password")
            echoMode: TextInput.Password
            Keys.onEnterPressed: validate()
            Keys.onReturnPressed: validate()
            Layout.fillWidth: true
            KeyNavigation.backtab: unlockBtn
            KeyNavigation.tab: rememberPasswordCheckBox
            onSubmit: validate()
        }

        StyledCheckBox {
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            id: rememberPasswordCheckBox
            text: qsTr("Remember password")
            description: qsTr("Don't ask again on this device.")
            KeyNavigation.backtab: passwordField.textField
            KeyNavigation.tab: unlockBtn
            Layout.bottomMargin: 32
        }

        StyledButton {
            id: unlockBtn
            text: qsTr("Unlock")
            toolTipText: qsTr("Unlock YubiKey")
            enabled: passwordField.text.valueOf().length > 0
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            onClicked: validate()
            KeyNavigation.backtab: rememberPasswordCheckBox
            KeyNavigation.tab: passwordField.textField
        }
    }
}
