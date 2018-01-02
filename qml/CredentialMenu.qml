import QtQuick 2.5
import QtQuick.Controls 1.4

Menu {

    property var credential
    property bool showGenerate
    property bool enableGenerate

    MenuItem {
        action: copyAction
    }

    MenuItem {
        visible: showGenerate
        enabled: enableGenerate
        text: qsTr("Generate code")
        onTriggered: generate(false)
    }

    MenuSeparator {
    }

    MenuItem {
        text: qsTr("Delete")
        onTriggered: deleteCredential()
    }
}
