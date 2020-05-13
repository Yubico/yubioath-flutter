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
    Overlay.modal: Rectangle {
        color: "#66000000"
    }

    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: app.width * 0.9 > 600 ? 600 : app.width * 0.9

    background: Rectangle {
        color: defaultBackground
        radius: 4
    }

    property var globalResp: null

    function scanQr() {
        error = false
        success = false
        scanning = true
        currentCredentialCard = null
        yubiKey.parseQr(ScreenShot.capture(), function (resp) {
            scanning = false
            if (resp.success) {
                success = true
                globalResp = resp
                successTimeout.start()
            } else {
                error = true
                errorTimeout.start()
            }
        })
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
        if (callCancelCb) {
            navigator.goToNewCredential()
        }
        navigator.focus = true
    }

    Component.onCompleted: btnAccept.forceActiveFocus()

    property var cancelCb
    property var acceptedCb
    property var callCancelCb: false
    property bool warning: true
    property bool buttons: true
    property bool scanning: false
    property bool success: false
    property bool error: false
    property string image
    property string heading
    property string description
    property string buttonCancel: qsTr("Cancel")
    property string buttonAccept: qsTr("Accept")

    Timer {
        id: successTimeout
        triggeredOnStart: false
        interval: 150
        onTriggered: {
            close()
            navigator.focus = true
            navigator.goToNewCredential(globalResp)
        }
    }

    Timer {
        id: errorTimeout
        triggeredOnStart: false
        interval: 3000
        onTriggered: error = false
    }

    ColumnLayout {
        width: parent.width

        Label {
            text: heading
            font.pixelSize: 14
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width
            visible: heading
        }

        StyledImage {
            id: qrImage
            source: image
            color: primaryColor
            opacity: lowEmphasis
            iconWidth: 100
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.topMargin: 8
            visible: source && !scanning && !success && !error
        }

        StyledImage {
            id: qrSuccess
            source: error ? "../images/clear.svg" : "../images/check.svg"
            color: error ? yubicoRed : yubicoGreen
            opacity: highEmphasis
            iconHeight: qrImage.height
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.topMargin: 8
            visible: success || error
        }

        Item {
            height: qrImage.height
            width: qrImage.width
            visible: scanning && !success && !error
            Layout.topMargin: 8
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            BusyIndicator {
                width: 40
                height: 40
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        Label {
            Layout.topMargin: 16
            text: description
            color: primaryColor
            opacity: highEmphasis
            font.pixelSize: 13
            lineHeight: 1.2
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            visible: description
            wrapMode: Text.WordWrap
            Layout.maximumWidth: parent.width > 400 ? 400 : parent.width
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.topMargin: 16

            StyledButton {
                id: btnAccept
                text: qsTr(buttonAccept)
                primary: true
                flat: false
                enabled: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                critical: warning
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                KeyNavigation.tab: btnCancel
                Keys.onReturnPressed: scanQr()
                onClicked: scanQr()
            }

            StyledButton {
                id: btnCancel
                text: qsTr(buttonCancel)
                critical: warning
                flat: true
                enabled: true
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                KeyNavigation.tab: btnAccept
                Keys.onReturnPressed: {
                    callCancelCb = true
                    reject()
                }
                onClicked: {
                   callCancelCb = true
                   reject()
                }
            }
        }
    }
}
