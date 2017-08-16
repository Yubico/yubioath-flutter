import QtQuick 2.5
import QtQuick.Controls 1.4

DefaultDialog {

    id: aboutPage
    title: qsTr("About Yubico Authenticator")

    Item {
        focus:true
        Keys.onEscapePressed: close()
    }

    Label {
        text: qsTr("Yubico Authenticator")
        font.bold: true
    }

    Label {
        text: qsTr("Version: ") + appVersion
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
