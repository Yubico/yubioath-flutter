import QtQuick 2.6
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2

ApplicationWindow {
    id: applicationWindow1
    width: 300
    height: 400
    visible: true
    title: qsTr("Yubico Authenticator")
    property int expiration: 0
    property var credentials: yk.credentials

    onCredentialsChanged: {
        updateExpiration()
        touchYourYubikey.close()
        console.log('CREDENTIALS    ', JSON.stringify(credentials))
    }

    menuBar: MenuBar {

        Menu {
            title: qsTr("File")
            MenuItem {
                text: qsTr("Exit")
                onTriggered: Qt.quit()
            }
        }

        Menu {
            title: qsTr("Help")
            MenuItem {
                text: qsTr("About Yubico Authenticator")
                onTriggered: aboutPage.show()
            }
        }
    }

    AboutPage {
        id: aboutPage
    }

    ColumnLayout {
        id: credentialsColumn
        spacing: 10
        visible: yk.hasDevice
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.top: parent.top

        ProgressBar {
            id: progressBar
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.maximumHeight: 10
            Layout.minimumHeight: 10
            Layout.minimumWidth: 300
            Layout.fillWidth: true
            maximumValue: 30
            minimumValue: 0
            style: ProgressBarStyle {
                progress: Rectangle {
                    color: "#83d714"
                }

                background: Rectangle {
                    color: "lightgray"
                }
            }
        }

        Repeater {
            id: repeater1
            model: credentials

            Rectangle {
                id: credentialRectangle
                color: "#00000000"
                anchors.left: parent.left
                anchors.leftMargin: 10
                Layout.fillWidth: true
                Layout.minimumHeight: 70
                Layout.alignment: Qt.AlignTop

                MouseArea {
                    anchors.fill: parent
                    onDoubleClicked: calculateCredential(modelData)
                }

                ColumnLayout {
                    spacing: 2
                    anchors.fill: parent
                    Text {
                        visible: hasIssuer(modelData.name)
                        text: qsTr('') + parseIssuer(modelData.name)
                        font.pointSize: 13
                    }
                    Text {
                        visible: modelData.code != null
                        text: qsTr('') + modelData.code
                        font.family: "Verdana"
                        font.pointSize: 22
                    }
                    Text {
                        id: credMessage
                        text: "Double-click to generate code."
                        visible: modelData.code == null
                        opacity: 0.6
                        font.family: "Verdana"
                        font.pointSize: 15
                    }
                    Text {
                        text: hasIssuer(modelData.name) ? qsTr('') + parseName(modelData.name) : modelData.name
                        font.pointSize: 13
                    }
                }
            }
        }
    }

    MessageDialog {
        id: touchYourYubikey
        icon: StandardIcon.Information
        title: qsTr("Touch your YubiKey")
        text: qsTr("Touch your YubiKey to generate the code.")
        standardButtons: StandardButton.NoButton
    }

    // @disable-check M301
    YubiKey {
        id: yk
        onError: {
            errorBox.text = traceback
            errorBox.open()
        }
    }

    Timer {
        id: ykTimer
        triggeredOnStart: true
        interval: 500
        repeat: true
        running: true
        onTriggered: yk.refresh()
    }

    Timer {
        id: progressBarTimer
        interval: 100
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            var timeLeft = expiration - (Date.now() / 1000)
            if (timeLeft <= 0 && progressBar.value > 0) {
                yk.refresh()
            }
            progressBar.value = timeLeft
        }
    }

    Text {
        visible: !yk.hasDevice
        id: noLoadedDeviceMessage
        text: if (yk.nDevices == 0) {
                  qsTr("No YubiKey detected")
              } else if (yk.nDevices == 1) {
                  qsTr("Connecting to YubiKey...")
              } else {
                  qsTr("Multiple YubiKeys detected!")
              }
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
    }

    MessageDialog {
        id: errorBox
        icon: StandardIcon.Critical
        title: qsTr("Error!")
        text: ""
        standardButtons: StandardButton.Ok
    }

    function hasIssuer(name) {
        return name.indexOf(':') !== -1
    }
    function parseName(name) {
        return name.split(":").slice(1).join(":")
    }
    function parseIssuer(name) {
        return name.split(":", 1)
    }

    function calculateCredential(credential) {
        yk.calculate(credential)
        if (credential.touch) {
            touchYourYubikey.open()
        }
    }

    function updateExpiration() {
        var maxExpiration = 0
        if (credentials !== null) {
            for (var i = 0; i < credentials.length; i++) {
                var exp = credentials[i].expiration
                if (exp !== null && exp > maxExpiration) {
                    maxExpiration = exp
                }
            }
            expiration = maxExpiration
        }
    }
}
