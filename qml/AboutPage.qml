import QtQuick 2.5
import QtQuick.Controls 1.4

DefaultDialog {

    id: aboutPage
    title: qsTr("About Yubico Authenticator")

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
        text: qsTr("Visit Yubico <a href='https://www.yubico.com/support/knowledge-base/'>Knowledge Base</a>")
        onLinkActivated: Qt.openUrlExternally(link)

        MouseArea {
           anchors.fill: parent
           acceptedButtons: Qt.NoButton
           cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
        }
    }
}
