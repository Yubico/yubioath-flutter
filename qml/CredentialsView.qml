import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Pane {
    id: pane
    objectName: 'credentialsView'

    anchors.fill: parent
    Accessible.ignored: true
    padding: 0
    spacing: 0

    property string title: ""

    function filteredCredentials() {
        if (entries !== null && toolBar.searchField.text.length > 0) {
            var filteredEntries = entriesComponent.createObject(app, {

                                                                })
            for (var i = 0; i < entries.count; i++) {
                var entry = entries.get(i)
                if (!!entry && !!entry.credential) {
                    if (entry.credential.key.toLowerCase().indexOf(
                                toolBar.searchField.text.toLowerCase(
                                    )) !== -1) {
                        filteredEntries.append(entry)
                    }
                }
            }
            return filteredEntries
        }
        return entries
    }

    function calculate() {
        if (grid.currentIndex !== -1) {
            grid.currentItem.calculateCard(true)
        }
    }

    Component {
        id: entriesComponent
        EntriesModel {
        }
    }

    NoCredentialsSection {
        id: noCredentialsSection
        visible: entries.count === 0 && (!!yubiKey.currentDevice && yubiKey.currentDeviceValidated)
        enabled: visible
        Accessible.ignored: true
    }

    NoResultsSection {
        id: noResultsSection
        visible: entries.count > 0 && (!!yubiKey.currentDevice && yubiKey.currentDeviceValidated)
                 && filteredCredentials().count === 0
        enabled: visible
        Accessible.ignored: true
    }

    NoYubiKeySection {
        id: noYubiKeySection
        // Make this section the default view to show when there is errors.
        visible: !yubiKey.availableDevices || (!credentialsSection.visible && !noResultsSection.visible && !noCredentialsSection.visible)
        enabled: visible
        Accessible.ignored: true
    }

    CredentialsSection {
        id: credentialsSection
        visible: entries.count > 0
        enabled: visible
    }

}
