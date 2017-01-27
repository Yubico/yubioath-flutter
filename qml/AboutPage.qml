import QtQuick 2.0

DefaultDialog {

    id: aboutPage
    title: qsTr("About Yubico Authenticator")

    Text {
        text: qsTr("Yubico Authenticator")
        font.bold: true
    }

    Text {
        text: qsTr("Version: ") + appVersion
    }

    Text {
        text: qsTr("Copyright © 2017, Yubico Inc. All rights reserved.")
    }

    Text {
        text: qsTr("Need help?")
        font.bold: true
    }

    Text {
        text: qsTr("Visit Yubico <a href='https://www.yubico.com/support/knowledge-base/'>Knowledge Base</a>")
        onLinkActivated: Qt.openUrlExternally(link)

        MouseArea {
           anchors.fill: parent
           acceptedButtons: Qt.NoButton
           cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
        }
    }
}
