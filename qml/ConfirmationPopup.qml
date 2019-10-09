import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2

Dialog {
    margins: 0
    spacing: 0
    modal: true
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2

    width: app.width > 600 ? 600 : app.width * 0.8
    focus: true

    background: Rectangle {
        color: defaultBackground
        radius: 4
    }

    onClosed: {
        navigator.focus = true
    }

    onAccepted: {
        acceptedCb()
        close()
        navigator.focus = true
    }

    onRejected: {
        close()
        navigator.focus = true
    }

    Component.onCompleted: btnCancel.forceActiveFocus()

    property var acceptedCb

    property string heading
    property string message
    property string buttonCancel: qsTr("Cancel")
    property string buttonAccept: qsTr("Accept")

    ColumnLayout {
        width: parent.width
        Layout.fillWidth: true
        spacing: 0

        Label {
            id: confirmationHeading
            text: heading
            font.pixelSize: 14
            font.weight: Font.Medium
            width: parent.width
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
        }

        Label {
            id: confirmationLbl
            text: message
            color: formText
            font.pixelSize: 13
            lineHeight: 1.2
            wrapMode: Text.WordWrap
            Layout.topMargin: 16
            Layout.maximumWidth: parent.width
            width: parent.width
        }

        DialogButtonBox {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.topMargin: 14
            Layout.rightMargin: -22
            Layout.bottomMargin: -22

            StyledButton {
                id: btnAccept
                text: qsTr(buttonAccept)
                flat: true
                enabled: true
                font.capitalization: Font.capitalization
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                KeyNavigation.tab: btnCancel
                Keys.onReturnPressed: accept()
                onClicked: accept()
            }
            StyledButton {
                id: btnCancel
                text: qsTr(buttonCancel)
                flat: true
                enabled: true
                font.capitalization: Font.capitalization
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                KeyNavigation.tab: btnAccept
                Keys.onReturnPressed: reject()
                onClicked: reject()
            }
        }
    }
}
