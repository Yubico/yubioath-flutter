import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Pane {
    id: pane
    objectName: 'authenticatorView'

    Accessible.ignored: true
    padding: 0
    spacing: 0

    property string searchFieldPlaceholder:  entries.count > 0 ? qsTr("Search accounts") : ""
    property string searchQuery: toolBar.searchField.text
    property var currentCredentialCard: credentialsSection.currentCredentialCard

    height: app.height - toolBar.height

    function filteredCredentials() {
        if (entries !== null && searchQuery.length > 0) {
            var filteredEntries = entriesComponent.createObject(app)
            for (var i = 0; i < entries.count; i++) {
                var entry = entries.get(i)
                if (!!entry && !!entry.credential && entry.credential.key.match(escapeRegExp(searchQuery, "i"))) {
                    filteredEntries.append(entry)
                }
            }
            return filteredEntries
        }
        return entries
    }

    Pane {
        id: dropAreaOverlay
        anchors.centerIn: parent
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        width: app.width-8
        height: app.height-toolBar.height-8
        visible: false
        z: 200
        background: Rectangle {
            anchors.fill: parent
            color: isDark() ? "#ee111111" : "#eeeeeeee"
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            anchors.centerIn: parent

            StyledImage {
                id: yubikeys
                source: "../images/qr-scanner.svg"
                color: primaryColor
                opacity: lowEmphasis
                iconWidth: 110
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                bottomPadding: 16
            }

            Label {
                text: qsTr("Drop QR code")
                font.pixelSize: 16
                font.weight: Font.Normal
                lineHeight: 1.5
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                color: primaryColor
                opacity: highEmphasis
            }
            Label {
                text: qsTr("Drag and drop any image containing a QR code here.")
                horizontalAlignment: Qt.AlignHCenter
                Layout.minimumWidth: 300
                Layout.maximumWidth: app.width - dynamicMargin
                                     < dynamicWidthSmall ? app.width - dynamicMargin : dynamicWidthSmall
                Layout.rowSpan: 1
                lineHeight: 1.1
                wrapMode: Text.WordWrap
                font.pixelSize: 13
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                color: primaryColor
                opacity: lowEmphasis
            }
        }
    }

    DropArea {
        id: dropArea;
        anchors.fill: parent
        onEntered: {
            drag.accept (Qt.LinkAction);
            dropAreaOverlay.visible = true
        }
        onExited: dropAreaOverlay.visible = false
        onDropped: {
            dropAreaOverlay.visible = false
            var url = drop.urls[0]
            var file
            if (url.includes("file")) {
                if (Qt.platform.os === "windows") {
                    file = url.replace(/^(file:\/{3})/,"")
                } else {
                    file = url.replace(/^(file:\/{2})/,"")
                }
                yubiKey.scanQr(ScreenShot.capture(file))
            } else {
                yubiKey.scanQr(url)
            }
        }
    }


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
                 && filteredCredentials().count === 0
        enabled: visible
        Accessible.ignored: true
    }

    NoYubiKeySection {
        id: noYubiKeySection
        // Make this section the default view to show when there is errors.
        visible: !credentialsSection.visible && !noResultsSection.visible && !noCredentialsSection.visible
        enabled: visible
        Accessible.ignored: true
    }

    CredentialsSection {
        id: credentialsSection
        visible: entries.count > 0
        enabled: visible
    }


}
