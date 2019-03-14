import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2

Pane {
    objectName: 'settingsView'

    property string title: "Settings"

    ColumnLayout {
        Label {
            text: "Settings"
        }
        Button {
            text: "toggle theme"
            onClicked: app.toggleTheme()
        }
    }
}
