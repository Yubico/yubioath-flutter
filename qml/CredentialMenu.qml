import QtQuick 2.5
import QtQuick.Controls 1.4

Menu {

    property var credential
    property bool showGenerate
    property bool enableGenerate

    MenuItem {
        text: qsTr("\&Copy to clipboard")
        enabled: (credential != null) && (credential.code != null)
        onTriggered: copy()
    }

    MenuItem {
        visible: showGenerate
        enabled: enableGenerate
        text: qsTr("Generate code")
        onTriggered: generate()
    }

    MenuSeparator {
    }

    MenuItem {
        text: qsTr("Delete")
        onTriggered: deleteCredential()
    }
}
