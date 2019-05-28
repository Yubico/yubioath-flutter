import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2

Dialog {
    margins: 0
    modal: true
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2

    width: app.width > 600 ? 600 : app.width * 0.8
    standardButtons: Dialog.Cancel | Dialog.Ok
    onAccepted: acceptedCb()
    focus: true

    property var acceptedCb

    property string heading
    property string message

    ColumnLayout {
        width: parent.width
        spacing: 16

        Label {
            id: confirmationHeading
            text: heading
            font.pixelSize: 16
            font.weight: Font.Medium
            width: parent.width
            Layout.maximumWidth: parent.width
        }

        Label {
            id: confirmationLbl
            text: message
            color: formText
            font.pixelSize: 14
            lineHeight: 1.2
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
            width: parent.width
        }
    }
}
