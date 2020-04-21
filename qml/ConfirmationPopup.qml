import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import QtQuick.Controls.Material 2.2

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
        close()
        acceptedCb()
        navigator.focus = true
    }

    onRejected: {
        close()
        navigator.focus = true
    }

    Component.onCompleted: btnCancel.forceActiveFocus()

    property var acceptedCb
    property bool warning: true
    property bool buttons: true
    property string heading
    property string message
    property string description
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
            visible: message
            width: parent.width
            Layout.minimumWidth: parent.width
            Layout.maximumWidth: parent.width
            Layout.topMargin: 16
            background: Rectangle {
                color: warning ? yubicoRed : yubicoGreen
                radius: 4
            }

            RowLayout {
                spacing: 0
                width: parent.width
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                StyledImage {
                    source: warning ? "../images/warning.svg" : "../images/info.svg"
                    color: defaultBackground
                    iconWidth: 32
                    iconHeight: 32
                    Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    Layout.maximumWidth: 32
                    visible: message
                }

                Label {
                    text: message
                    color: defaultBackground
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    lineHeight: 1.2
                    leftPadding: 12
                    wrapMode: Text.WordWrap
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.fillWidth: true
                    visible: message
                }
            }
        }

        Label {
            Layout.topMargin: 16
            text: description
            color: primaryColor
            opacity: highEmphasis
            font.pixelSize: 13
            lineHeight: 1.2
            visible: description
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
                primary: true
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
