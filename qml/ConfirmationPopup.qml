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
        color: defaultBackground
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
        navigator.focus = true
    }

    onRejected: {
        close()
        if (cancelCb) {
            cancelCb()
        }
        navigator.focus = true
    }

    property var currentDevice: yubiKey.currentDevice

    onCurrentDeviceChanged: {
        if(closePolicy === Popup.NoAutoClose) {
            close()
        }
    }

    Component.onCompleted: btnAccept.forceActiveFocus()

    property var cancelCb
    property var acceptedCb
    property bool warning: true
    property bool buttons: true
    property bool noicon: false
    property string image
    property string heading
    property string message
    property string description
    property string buttonCancel: qsTr("Cancel")
    property string buttonAccept: qsTr("Accept")

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
            visible: heading
        }

        RowLayout {
            spacing: 0
            width: parent.width
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            Layout.bottomMargin: description ? 16 : 0
            visible: message

            StyledImage {
                source: warning ? "../images/warning.svg" : "../images/info.svg"
                color: warning ? yubicoRed : defaultForeground
                iconWidth: 32
                iconHeight: 32
                Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                Layout.maximumWidth: 48
                visible: message && !noicon
            }

            Label {
                text: message
                color: primaryColor
                opacity: highEmphasis
                font.pixelSize: 13
                font.weight: Font.Medium
                lineHeight: 1.2
                wrapMode: Text.WordWrap
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                Layout.fillWidth: true
                visible: message
            }
        }

        Label {
            text: description
            color: primaryColor
            opacity: lowEmphasis
            font.pixelSize: 13
            lineHeight: 1.2
            visible: description
            textFormat: TextEdit.RichText
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
        }

        DialogButtonBox {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.topMargin: 8
            Layout.bottomMargin: -8
            padding: 0
            visible: buttons

            StyledButton {
                id: btnAccept
                text: qsTr(buttonAccept)
                enabled: true
                critical: warning
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                KeyNavigation.tab: btnCancel
                Keys.onReturnPressed: accept()
                onClicked: accept()
            }

            StyledButton {
                id: btnCancel
                text: qsTr(buttonCancel)
                critical: warning
                enabled: true
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                KeyNavigation.tab: btnAccept
                Keys.onReturnPressed: reject()
                onClicked: reject()
            }
        }
    }
}
