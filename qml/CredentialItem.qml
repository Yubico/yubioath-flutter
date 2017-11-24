import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1

Rectangle {
    property var code
    property var credential
    property bool isExpired: true
    property bool isSelected: false
    property bool timerRunning: false
    property color unselectedColor

    signal singleClick(var mouse)
    signal doubleClick(var mouse)
    signal refresh(bool force)

    readonly property bool hasCustomTimeBar: (
        credential.period !== 30 || (credential.touch && code && !isExpired)
    )
    readonly property color textColor: (isSelected
        ? palette.highlightedText
        : palette.windowText
    )

    color: (isSelected
        ? palette.highlight
        : unselectedColor
    )

    Layout.minimumHeight: (
        10 + issuerLbl.height + codeLbl.height + nameLbl.height
            + (hasCustomTimeBar ? 10 : 0)
    )
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignTop

    MouseArea {
        anchors.fill: parent
        onClicked: singleClick(mouse)
        onDoubleClicked: doubleClick(mouse)
        acceptedButtons: Qt.RightButton | Qt.LeftButton
    }

    ColumnLayout {
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 5
        anchors.bottomMargin: 5
        anchors.fill: parent
        spacing: 0
        Label {
            id: issuerLbl
            visible: credential.issuer != null
                     && credential.issuer.length > 0
            text: qsTr("") + credential.issuer
            color: textColor
        }
        Label {
            id: codeLbl
            opacity: isExpired ? 0.6 : 1
            visible: code !== null
            text: qsTr("") + getSpacedCredential(code && code.value)
            font.pointSize: issuerLbl.font.pointSize * 1.8
            color: textColor
        }
        Label {
            id: nameLbl
            text: credential.name
            color: textColor
        }
        Timer {
            interval: 100
            repeat: true
            running: timerRunning && hasCustomTimeBar
            triggeredOnStart: true
            onTriggered: {
                var timeLeft = code.valid_to - (Date.now() / 1000)
                if (timeLeft <= 0 && customTimeLeftBar.value > 0) {
                    refresh(true)
                }
                customTimeLeftBar.value = timeLeft
            }
        }
        ProgressBar {
            id: customTimeLeftBar
            visible: hasCustomTimeBar
            Layout.topMargin: 3
            Layout.fillWidth: true
            Layout.minimumHeight: 7
            Layout.maximumHeight: 7
            Layout.alignment: Qt.AlignBottom
            maximumValue: credential.period || 0
            rotation: 180
        }
    }

    function getSpacedCredential(code) {
        // Add a space in the code for easier reading.
        if (code != null) {
            switch (code.length) {
            case 6:
                // 123 123
                return code.slice(0, 3) + " " + code.slice(3)
            case 7:
                // 1234 123
                return code.slice(0, 4) + " " + code.slice(4)
            case 8:
                // 1234 1234
                return code.slice(0, 4) + " " + code.slice(4)
            default:
                return code
            }
        }
    }

}
