import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1

Rectangle {
    property bool expired
    property var model
    property int repeaterIndex

    signal singleClick(var mouse, var entry)
    signal doubleClick(var mouse, var entry)

    color: getCredentialColor(index, model)
    Layout.minimumHeight: {
        var baseHeight = issuerLbl.height
                + codeLbl.height + nameLbl.height + 10
        return hasCustomTimeBar(
                    model.credential) ? baseHeight
                                 + 10 : baseHeight
    }
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignTop

    MouseArea {
        anchors.fill: parent
        onClicked: singleClick(mouse, model)
        onDoubleClicked: doubleClick(mouse, model)
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
            visible: model.credential.issuer != null
                     && model.credential.issuer.length > 0
            text: qsTr("") + model.credential.issuer
            color: getCredentialTextColor(model)
        }
        Label {
            id: codeLbl
            opacity: expired ? 0.6 : 1
            visible: model.code !== null
            text: qsTr("") + getSpacedCredential(
                      model.code && model.code.value)
            font.pointSize: issuerLbl.font.pointSize * 1.8
            color: getCredentialTextColor(model)
        }
        Label {
            id: nameLbl
            text: model.credential.name
            color: getCredentialTextColor(model)
        }
        Timer {
            interval: 100
            repeat: true
            running: displayTimersRunning && hasCustomTimeBar(model.credential)
            triggeredOnStart: true
            onTriggered: {
                var timeLeft = model.code.valid_to - (Date.now() / 1000)
                if (timeLeft <= 0
                        && customTimeLeftBar.value > 0) {
                    refreshDependingOnMode(true)
                }
                customTimeLeftBar.value = timeLeft
            }
        }
        ProgressBar {
            id: customTimeLeftBar
            visible: hasCustomTimeBar(model.credential)
            Layout.topMargin: 3
            Layout.fillWidth: true
            Layout.minimumHeight: 7
            Layout.maximumHeight: 7
            Layout.alignment: Qt.AlignBottom
            maximumValue: model.credential.period || 0
            rotation: 180
        }
    }

    function hasCustomTimeBar(cred) {
        return cred.period !== 30 && (cred.oath_type === 'TOTP' || cred.touch)
    }

    function getCredentialTextColor(entry) {
        if (selected != null && selected.credential.key === entry.credential.key) {
            return palette.highlightedText
        } else {
            return palette.windowText
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
