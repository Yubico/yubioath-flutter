import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {

    id: enterPasswordViewId
    objectName: 'enterPasswordView'

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

    function validate() {
        if (passwordField.text.valueOf().length > 0) {
            yubiKey.validate(passwordField.text, rememberPasswordCheckBox.checked, function (resp) {
                if (resp.success) {
                    navigator.goToAuthenticator()
                } else {
                    passwordField.error = true  
                    passwordField.textField.selectAll()
                    passwordField.forceActiveFocus()
                    rememberPasswordCheckBox.checked = false
                    console.log("validate failed:", resp.error_id)
                }
            })
        }
    }

    onFocusChanged: {
        passwordField.forceActiveFocus()
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
            Layout.topMargin: 24
            Layout.bottomMargin: 12
        }

        Label {
            text: qsTr("Enter the password for your YubiKey. If you don't know your password, you'll need to reset the YubiKey.")
            color: primaryColor
            opacity: highEmphasis
            font.pixelSize: 13
            lineHeight: 1.2
            visible: manageMode
            textFormat: TextEdit.RichText
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
            Layout.bottomMargin: 16
        }

        StyledTextField {
            id: passwordField
            labelText: qsTr("Password")
            echoMode: TextInput.Password
            validateText: "Wrong password"
            Keys.onEnterPressed: validate()
            Keys.onReturnPressed: validate()
            Layout.fillWidth: true
            KeyNavigation.backtab: unlockBtn
            KeyNavigation.tab: rememberPasswordCheckBox
            onSubmit: validate()
            Layout.bottomMargin: 16
        }

        CheckBox {
            id: rememberPasswordCheckBox
            text: qsTr("Remember password")
            opacity: highEmphasis
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            KeyNavigation.backtab: passwordField.textField
            KeyNavigation.tab: unlockBtn
            Layout.bottomMargin: 16
        }

        StyledButton {
            id: unlockBtn
            text: qsTr("Unlock")
            toolTipText: qsTr("Unlock YubiKey")
            enabled: passwordField.text.valueOf().length > 0
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            onClicked: validate()
            Keys.onEnterPressed: validate()
            Keys.onReturnPressed: validate()
            KeyNavigation.backtab: rememberPasswordCheckBox
            KeyNavigation.tab: passwordField.textField
        }
    }
}
