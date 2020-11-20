import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

StyledExpansionPanel {
    label: qsTr("Appearance")
    description: qsTr("Change the visual appearance of the application.")
    metadata: "dark light mode theme language"
    isTopPanel: true

    ListModel {
        id: languages

        ListElement {
            text: qsTr("System default")
            value: ""
        }
        ListElement {
            text: qsTr("English")
            value: "en"
        }
        ListElement {
            text: qsTr("French")
            value: "fr"
        }
    }

    ColumnLayout {
        RowLayout {
            Layout.fillWidth: true
            StyledComboBox {
                id: languageComboBox
                label: qsTr("Language")
                comboBox.textRole: "text"
                model: languages
                onCurrentIndexChanged: {
                    settings.language = languages.get(currentIndex).value
                }
                currentIndex: {
                    switch (settings.language) {
                    case "":
                        return 0
                    case "en":
                        return 1
                    case "fr":
                        return 2
                    default:
                        return 0
                    }
                }
            }
        }
    }

    ListModel {
        id: themes

        ListElement {
            text: qsTr("System default")
            value: Material.System
        }
        ListElement {
            text: qsTr("Light mode")
            value: Material.Light
        }
        ListElement {
            text: qsTr("Dark mode")
            value: Material.Dark
        }
    }

    ColumnLayout {
        RowLayout {
            Layout.fillWidth: true
            StyledComboBox {
                id: themeComboBox
                label: qsTr("Theme")
                comboBox.textRole: "text"
                model: themes
                onCurrentIndexChanged: {
                    settings.theme = themes.get(currentIndex).value
                }
                currentIndex: {
                    switch (settings.theme) {
                    case Material.System:
                        return 0
                    case Material.Light:
                        return 1
                    case Material.Dark:
                        return 2
                    default:
                        return 0
                    }
                }
            }
        }
    }
}
