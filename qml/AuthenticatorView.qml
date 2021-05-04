import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {
    id: pane
    objectName: 'authenticatorView'

    Accessible.ignored: true
    //padding: 0
    //spacing: 0

    contentWidth: app.width
    contentHeight: accountList.height

//    onExpandedHeightChanged: {
//        if (expandedHeight > app.height - toolBar.height) {
//             scrollBar.active = true
//         }
//    }
    flickableDirection: Flickable.VerticalFlick

    ScrollBar.vertical: ScrollBar {
        id: paneScrollBar
        width: 8
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        hoverEnabled: true
        z: 10
    }

    property string searchFieldPlaceholder: entries.count > 0 ? qsTr("Search accounts") : ""
    property string searchQuery: toolBar.searchField.text
    property var currentCredentialCard: credentialsSectionFavorites.currentIndex !== -1
                                        ? credentialsSectionFavorites.currentCredentialCard
                                        : credentialsSection.currentCredentialCard

    height: app.height - toolBar.height

    Component {
        id: entriesComponent
        EntriesModel {
        }
    }

    NoCredentialsSection {
        id: noCredentialsSection
        visible: entries.count === 0 && yubiKey.currentDeviceEnabled("OATH")
        enabled: visible
        Accessible.ignored: true
    }

    NoResultsSection {
        id: noResultsSection
        visible: entries.count > 0 && !!yubiKey.currentDevice
                 && !credentialsSection.visible && !credentialsSectionFavorites.visible
        enabled: visible
        Accessible.ignored: true
    }

    NoYubiKeySection {
        id: noYubiKeySection
        // Make this section the default view to show when there is errors.
        visible: !credentialsSection.visible && !credentialsSectionFavorites.visible && !noResultsSection.visible && !noCredentialsSection.visible
        enabled: visible
        Accessible.ignored: true
    }

    ColumnLayout {
        id: accountList
        width: parent.width

        Label {
            font.pixelSize: 10
            color: primaryColor
            opacity: disabledEmphasis
            text: qsTr("Favorites")
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 1
            Layout.leftMargin: 16
            Layout.topMargin: 8
            visible: credentialsSectionFavorites.visible
        }

        CredentialsSection {
            id: credentialsSectionFavorites
            visible: model.count > 0
            model: getEntries(searchQuery, true)
            enabled: true
            Layout.fillWidth: true
            onCurrentItemChanged: credentialsSection.currentIndex = -1
    //        anchors.left: parent.left
    //        anchors.right: parent.right
    //        anchors.top: parent.top
        }

        Label {
            font.pixelSize: 10
            color: primaryColor
            opacity: disabledEmphasis
            text: qsTr("Accounts")
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 1
            Layout.leftMargin: 16
            Layout.topMargin: 8
            visible: credentialsSection.visible
        }

        CredentialsSection {
            id: credentialsSection
            visible: model.count > 0
            model: getEntries(searchQuery, false)
            enabled: visible
            Layout.fillWidth: true
            Layout.fillHeight: true
            onCurrentItemChanged: credentialsSectionFavorites.currentIndex = -1
    //        anchors.left: parent.left
    //        anchors.right: parent.right
    //        anchors.top: credentialsSectionFavorites.bottom
            //anchors.bottom: parent.bottom
        }

    }

}
