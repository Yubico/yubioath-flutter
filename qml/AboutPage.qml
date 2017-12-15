import QtQuick 2.5
import QtQuick.Controls 1.4
import "utils.js" as Utils

DefaultDialog {

    id: aboutPage
    title: qsTr("About Yubico Authenticator")
    property var device
    property bool slotMode

    Item {
        focus:true
        Keys.onEscapePressed: close()
    }

    Label {
        text: qsTr("Yubico Authenticator ") + appVersion
        font.bold: true
    }

    Label {
        visible: !slotMode
        text: qsTr("YubiKey OATH Version: ") + (!slotMode && device.hasDevice ? Utils.versionString(device.version) : qsTr("<i>No device</i>"))
    }

    Label {
        text: qsTr("Copyright © 2017, Yubico Inc. All rights reserved.")
    }

    Label {
        text: qsTr("Need help?")
        font.bold: true
    }

    Label {
        text: qsTr("Visit <b>Yubico Knowledge Base</b>.")
        MouseArea {
           anchors.fill: parent
           acceptedButtons: Qt.LeftButton
           cursorShape: Qt.PointingHandCursor
           onClicked: Qt.openUrlExternally("https://www.yubico.com/support/knowledge-base/")
        }
    }
}
