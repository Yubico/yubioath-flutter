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
        destroy()
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
    property bool done: false
    property bool removed: false
    property bool ready: removed && yubiKey.availableDevices.length === 1
    property var currentDevice: !!yubiKey.currentDevice && yubiKey.currentDevice
    property bool devRemoved: yubiKey.deviceRemoved

    onDevRemovedChanged: {
        if (devRemoved) {
            removed = true
        }
    }

    onCurrentDeviceChanged: {
        if (settings.useCustomReader && !ready) {
            yubiKey.connectToCustomReader()
        }


        if (yubiKey.availableDevices.length === 0) {
            progressBar.value = 0.33
            removed = true
        }
    }

    onReadyChanged: {
        if (settings.useCustomReader) {
            progressBar.value = 0.5
        } else {
            progressBar.value = 0.66
        }
        yubiKey.fidoReset(function (resp) {
            if (resp.success) {
                progressBar.value = 1
                done = true
                yubiKey.deviceRemoved = false
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
            text: "Follow the instructions to perform a reset, abort at any time."
            visible: !settings.useCustomReader
            color: primaryColor
            opacity: lowEmphasis
            font.pixelSize: 13
            lineHeight: 1.2
            textFormat: TextEdit.RichText
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
            Layout.bottomMargin: 16
         }

        Label {
            text: "Follow the instructions to perform a reset, abort at any time."
            visible: settings.useCustomReader
            color: primaryColor
            opacity: lowEmphasis
            font.pixelSize: 13
            lineHeight: 1.2
            textFormat: TextEdit.RichText
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
            Layout.bottomMargin: 16
         }

        Label {
            id: lblStatus
            text: {
                if (!settings.useCustomReader) {
                    if(done) {
                        return qsTr("Done")
                    }
                    if (ready) {
                        return qsTr("Touch your yubikey")
                    }
                    if (removed) {
                        return qsTr("Reinsert your YubiKey")
                    }
                    if (!ready && !removed) {
                        return qsTr("Remove your YubiKey")
                    }
                } else {
                    return qsTr("To continue, remove and re-place your YubiKey")
                }
            }
            color: primaryColor
            opacity: lowEmphasis
            font.pixelSize: 13
            lineHeight: 1.2
            textFormat: TextEdit.RichText
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
            Layout.bottomMargin: 16
         }

        ProgressBar {
            id: progressBar
            value: 0
            Layout.fillWidth: true
            Layout.bottomMargin: 16
        }


        DialogButtonBox {
            visible: !done
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.bottomMargin: 0
            padding: 0
            background: Rectangle {
                color: "transparent"
            }

            StyledButton {
                id: btnCancel
                text: qsTr("Cancel")
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                onClicked: {
                    if (settings.useCustomReader)
                        reset_cancel()
                    else
                        reject()
                }
                Keys.onReturnPressed: reject()
            }
        }

        DialogButtonBox {
            visible: done
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.bottomMargin: 0
            padding: 0
            background: Rectangle {
                color: "transparent"
            }

            StyledButton {
                id: btnAccept
                text: qsTr("Continue")
                primary: true
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                Keys.onReturnPressed: accept()
                onClicked: accept()
            }
        }

    }

    function reset_cancel() {
        yubiKey.resetCancel()
        reject()
    }
}
