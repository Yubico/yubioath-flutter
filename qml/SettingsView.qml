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
            id: button
            flat: true
            text: "<font color='#fefefe'>Toggle theme</font>"
            hoverEnabled: true
            font.capitalization: Font.MixedCase
            font.bold: false
            font.pointSize: 13
            onClicked: app.toggleTheme()
            implicitHeight: 44
            leftPadding: 12
            rightPadding: 12
            background: Rectangle {
                radius: 2
                color: button.hovered ? "#a6d14c" : yubicoGreen // beginning of new default button (color is temporary)
            }
        }
    }
}
