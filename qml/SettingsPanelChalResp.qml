import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import QtQuick.Controls.Material 2.2

ColumnLayout {
    property bool changed: secretKeyInput.text !== ""


    RowLayout {
        StyledTextField {
            id: secretKeyInput
            labelText: qsTr("Secret key")
            validator: validator
        }

        ToolButton {
            id: btnGenerateSecretKey
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom

            onClicked: generateSecretKey()
            Keys.onReturnPressed: generateSecretKey()
            Keys.onEnterPressed: generateSecretKey()

            Accessible.role: Accessible.Button
            Accessible.name: "Generate"
            Accessible.description: "Generate a random secret key"

            ToolTip {
                text: qsTr("Generate a random secret key")
                delay: 1000
                parent: parent
                visible: parent.hovered
                Material.foreground: toolTipForeground
                Material.background: toolTipBackground
            }

            icon.source: "../images/refresh.svg"
            icon.color: primaryColor
            opacity: hovered ? fullEmphasis : lowEmphasis

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: false
            }
        }
    }

    RowLayout {
        CheckBox {
            id: requireTouchCb
            text: qsTr("Require touch")
            ToolTip.delay: 1000
            ToolTip.visible: hovered
            ToolTip.text: qsTr("YubiKey will require a touch for the challenge-response operation")
        }
    }

    function generateSecretKey() {
        yubiKey.randomKey(20, function (res) {
            secretKeyInput.text = res
        })
    }

    RegExpValidator {
        id: validator
        regExp: /([0-9a-fA-F]{2}){1,20}$/
    }

    function programChallengeResponse(slot) {
        yubiKey.programChallengeResponse(slot,
                                         secretKeyInput.text,
                                         requireTouchCb.checked,
                                         function (resp) {
                                             if (resp.success) {
                                                 navigator.snackBar(
                                                             qsTr("Configured Challenge-Response credential"))
                                             } else {
                                                 if (resp.error_id === 'write error') {
                                                     navigator.snackBar(qsTr("Failed to modify. Make sure the YubiKey does not have restricted access."))
                                                 } else {
                                                     navigator.snackBarError(
                                                                 navigator.getErrorMessage(
                                                                     resp.error_id))
                                                 }
                                             }
                                         })
    }
}


