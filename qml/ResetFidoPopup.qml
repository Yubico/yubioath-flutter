import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.2
import QtQuick.Controls.Material 2.2

Dialog {
    padding: 16
    margins: 0
    spacing: 0
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    Overlay.modal: Rectangle {
        color: "#55000000"
    }

    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: app.width * 0.9 > 600 ? 600 : app.width * 0.9

    background: Rectangle {
        color: defaultElevated
        radius: 4
    }

    onClosed: {
        navigator.focus = true
    }

    onAccepted: {
        close()
        if(acceptedCb) {
            acceptedCb()
        }
    }

    onRejected: {
        close()
        if (cancelCb) {
            cancelCb()
        }
    }

    property var cancelCb
    property var acceptedCb
    property bool removed: false
    property bool ready: removed && yubiKey.availableDevices.length === 1
    property var currentDevice: yubiKey.currentDevice

    onCurrentDeviceChanged: {
        if (yubiKey.availableDevices.length === 0) {
            removed = true
        }
    }

    onReadyChanged: {
        yubiKey.fidoReset(function (resp) {
            if (resp.success) {
                navigator.snackBar("FIDO applications have been reset")
                accept()
            } else {
                if (resp.error_id === 'touch timeout') {
                    navigator.snackBarError(qsTr("A reset requires a touch on the YubiKey to be confirmed."))
                } else if (resp.error_message) {
                    navigator.snackBarError(resp.error_message)
                } else {
                    navigator.snackBarError(resp.error_id)
                }
                reject()
            }
        })
    }

    ColumnLayout {
        width: parent.width
        spacing: 0

        Label {
            text: qsTr("Reset your YubiKey")
            font.pixelSize: 14
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
            Layout.bottomMargin: 16
        }

        Label {
            text: ready ? qsTr("To continue, touch your yubikey") : qsTr("To continue, remove and re-insert your YubiKey")
            color: primaryColor
            opacity: lowEmphasis
            font.pixelSize: 13
            lineHeight: 1.2
            textFormat: TextEdit.RichText
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
        }

        DialogButtonBox {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.topMargin: 16
            Layout.bottomMargin: 0
            padding: 0
            background: Rectangle {
                color: "transparent"
            }

            StyledButton {
                id: btnCancel
                text: qsTr("Cancel")
                enabled: true
                flat: true
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                Keys.onReturnPressed: reject()
                onClicked: reject()
            }
        }
    }
}
