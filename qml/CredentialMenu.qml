import QtQuick 2.5
import QtQuick.Controls 1.4

Menu {

    property var credential
    property bool showGenerate
    property bool enableGenerate

    signal copy
    signal generate
    signal deleteCredential

    MenuItem {
        text: qsTr('Copy')
        shortcut: StandardKey.Copy
        enabled: (credential != null) && (credential.code != null)
        onTriggered: copy()
    }

    MenuItem {
        visible: showGenerate
        enabled: enableGenerate
        text: qsTr("Generate code")
        shortcut: "Space"
        onTriggered: generate()
    }

    MenuItem {
        text: qsTr("Delete")
        shortcut: StandardKey.Delete
        onTriggered: deleteCredential()
    }
}
