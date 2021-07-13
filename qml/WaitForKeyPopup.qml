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

    property string heading: qsTr("Remove YubiKey(s)")
    property string description: qsTr("Make sure there is only one YubiKey inserted before proceeding.")
    property var cancelCb
    property var acceptedCb
    property var reinsert: false
    property bool nobuttons: false
    property bool noDevice: yubiKey.availableDevices.length === 0
    property bool ready: !reinsert && yubiKey.availableDevices.length === 1

    onNoDeviceChanged: {
        if (!reinsert) {
            reject()
        } else {
            reinsert = false
        }
    }

    ColumnLayout {
        width: parent.width
        spacing: 0

        Label {
            text: heading
            font.pixelSize: 14
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
            Layout.bottomMargin: 16
        }

        Label {
            text: description
            color: primaryColor
            opacity: lowEmphasis
            font.pixelSize: 13
            lineHeight: 1.2
            textFormat: TextEdit.RichText
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
         }

        DialogButtonBox {
            visible: !ready && !nobuttons
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
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                onClicked: reject()
                Keys.onReturnPressed: reject()
            }
        }

        DialogButtonBox {
            visible: ready && !nobuttons
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.topMargin: 16
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
}
