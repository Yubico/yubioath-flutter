import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2

ApplicationWindow {

    id: app

    width: 800
    height: 400
    visible: true

    readonly property string yubicoGreen: "#9aca3c"
    readonly property string yubicoBlue: "#284c61"
    readonly property string yubicoWhite: "#FFFFFF"
    readonly property string yubicoGrey: "#939598"

    readonly property string defaultDark: "#303030"
    readonly property string defaultLight: "#FAFAFA"

    Material.theme: Material.System
    Material.primary: yubicoGreen
    Material.accent: yubicoBlue

    header: ToolBar {

        RowLayout {
            anchors.fill: parent

            ToolButton {
                text: qsTr("‹")
            }

            TextField {
                placeholderText: "Search.."
                horizontalAlignment: Qt.AlignHCenter
                verticalAlignment: Qt.AlignVCenter
                Layout.fillWidth: true
                background.width: width
            }

            ToolButton {
                text: qsTr("⋮")
            }
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        Pane {
            GridLayout {
                columnSpacing: 20
                rowSpacing: 20
                columns: app.width / 300

                Repeater {
                    model: 10
                    CredentialCard {
                    }
                }

                CredentialCard {
                    issuer: ""
                    name: "i only have name!"
                }

                Button {
                    text: "toggle theme"
                    onClicked: toggleTheme()
                }
            }
        }
    }

    function isDark() {
        return app.Material.theme === Material.Dark
    }

    function toggleTheme() {
        if (isDark()) {
            app.Material.theme = Material.Light
        } else {
            app.Material.theme = Material.Dark
        }
    }
}
