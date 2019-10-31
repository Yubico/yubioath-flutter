import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2

Dialog {
    padding: 16
    margins: 0
    spacing: 0
    modal: true
    focus: true

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
    property string primaryMessage
    property string secondaryMessage
    property string buttonCancel: qsTr("Cancel")
    property string buttonAccept: qsTr("Accept")

    ColumnLayout {
        width: parent.width

        Label {
            text: heading
            font.pixelSize: 14
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
        }

        Pane {
            padding: 12
            rightPadding: 16
            bottomPadding: 8
            visible: primaryMessage
            width: parent.width
            Layout.topMargin: 16
            Layout.maximumWidth: parent.width
            Layout.fillWidth: true
            background: Rectangle {
                color: yubicoRed
            }

            RowLayout {
                spacing: 0
                width: parent.width
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                StyledImage {
                    source: "../images/warning.svg"
                    color: yubicoWhite
                    iconWidth: 32
                    iconHeight: 32
                    Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    Layout.maximumWidth: 32
                }

                Label {
                    text: primaryMessage
                    color: yubicoWhite
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    lineHeight: 1.2
                    leftPadding: 12
                    wrapMode: Text.WordWrap
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.fillWidth: true
                }
            }
        }

        Label {
            Layout.topMargin: 16
            text: secondaryMessage
            color: formText
            font.pixelSize: 13
            lineHeight: 1.2
            visible: secondaryMessage
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
        }

        DialogButtonBox {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.topMargin: 8
            Layout.rightMargin: -8
            Layout.bottomMargin: -8

            StyledButton {
                id: btnAccept
                text: qsTr(buttonAccept)
                flat: true
                enabled: true
                critical: primaryMessage
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
                critical: primaryMessage
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
