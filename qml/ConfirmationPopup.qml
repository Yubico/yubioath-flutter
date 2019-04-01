import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2

Dialog {
    margins: 0
    modal: true
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2

    width: app.width * 0.7
    standardButtons: Dialog.No | Dialog.Yes
    onAccepted: acceptedCb()
    focus: true

    property var acceptedCb

    property string heading
    property string message

    ColumnLayout {
        width: parent.width
        spacing: 20

        Label {
            id: confirmationHeading
            text: heading
            font.bold: true
            width: parent.width
            Layout.maximumWidth: parent.width
        }

        Label {
            id: confirmationLbl
            text: message
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
            width: parent.width
        }
    }
}
