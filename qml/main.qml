import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2
import Qt.labs.settings 1.0

ApplicationWindow {
    id: appWindow
    width: 300
    height: 400
    minimumHeight: 400
    minimumWidth: 300
    visible: true
    title: getTitle()
    property var device: yk
    property var credentials: device.credentials
    property bool hasDevice: device.hasDevice
    property bool canShowCredentials: device.hasDevice && modeAndKeyMatch
                                      && device.validated
    property bool modeAndKeyMatch: slotModeMatch || ccidModeMatch
    property bool slotModeMatch: (settings.slotMode && device.hasOTP)
    property bool ccidModeMatch: (!settings.slotMode && device.hasCCID)
    property var hotpCoolDowns: []

    // Don't refresh credentials when window is minimized or hidden
    // See http://doc.qt.io/qt-5/qwindow.html#Visibility-enum
    property bool shouldRefresh: visibility != 3 && visibility != 0

    signal copy
    signal generate
    signal deleteCredential

    onDeleteCredential: confirmDeleteCredential.open()
    onGenerate: handleGenerate(repeater.selected)
    onCopy: clipboard.setClipboard(repeater.selected.code)

    onHasDeviceChanged: handleNewDevice()

    onCredentialsChanged: {
        hotpTouchTimer.stop()
        touchYourYubikey.close()
    }

    menuBar: MainMenuBar {
        slotMode: settings.slotMode
        hasDevice: device.hasDevice
        credential: repeater.selected
        enableGenerate: enableManualGenerate(repeater.selected)
        onOpenAddCredential: openClearAddCredential()
        onOpenSetPassword: setPassword.open()
        onOpenReset: reset.open()
        onOpenSettings: settingsDialog.open()
        onOpenAbout: aboutPage.open()
    }

    Shortcut {
        sequence: StandardKey.Close
        onActivated: close()
    }

    SystemPalette {
        id: palette
    }

    // This information is stored in the system registry on Windows,
    // and in XML preferences files on macOS. On other Unix systems,
    // in the absence of a standard, INI text files are used.
    // See http://doc.qt.io/qt-5/qml-qt-labs-settings-settings.html#details
    Settings {
        id: settings
        property bool slotMode
        property bool slot1
        property bool slot2
        property var slot1digits
        property var slot2digits
        property string savedPasswords

        // Keep track of window position and dimensions.
        property alias x: appWindow.x
        property alias y: appWindow.y
        property alias width: appWindow.width
        property alias height: appWindow.height
    }

    AboutPage {
        id: aboutPage
    }

    AddCredential {
        id: addCredential
        device: yk
    }

    AddCredentialSlot {
        id: addCredentialSlot
        settings: settings
        device: yk
    }

    SettingsDialog {
        id: settingsDialog
        settings: settings
        onAccepted: {
            saveSettings()
            refreshDependingOnMode(true)
        }
    }

    SetPassword {
        id: setPassword
        onAccepted: {
            trySetPassword()
            passwordUpdated.open()
            setPassword.clear()
        }
    }

    PasswordSetConfirmation {
        id: passwordUpdated
    }

    Reset {
        id: reset
        onAccepted: {
            device.reset()
            device.refreshCCIDCredentials(true)
            resetConfirmation.open()
        }
    }

    ResetConfirmation {
        id: resetConfirmation
    }

    PasswordPrompt {
        id: passwordPrompt
        onAccepted: handlePasswordEntered()
    }

    // @disable-check M301
    YubiKey {
        id: yk
        onError: console.log(traceback)
        onWrongPassword: passwordPrompt.open()
        onCredentialsRefreshed: flickable.restoreScrollPosition()
    }

    NoLoadedDeviceMessage {
        id: noLoadedDeviceMessage
        device: yk
    }

    LoadedDeviceMessage {
        id: loadedDeviceMessage
        device: yk
        nCredentials: filteredCredentials(credentials).length
        readingCredentials: credentials === null
        settings: settings
    }

    ClipBoard {
        id: clipboard
    }

    CredentialMenu {
        id: credentialMenu
        credential: repeater.selected
        showGenerate: allowManualGenerate(repeater.selected)
        enableGenerate: enableManualGenerate(repeater.selected)
    }

    DeleteCredentialConfirmation {
        id: confirmDeleteCredential
        onAccepted: {
            deleteSelectedCredential()
            refreshDependingOnMode(true)
        }
    }

    TouchYubiKey {
        id: touchYourYubikey
    }

    ArrowKeysSelecter {
        id: arrowKeys
        credRepeater: repeater
        KeyNavigation.tab: search
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TimeLeftBar {
            id: timeLeftBar
            shouldBeVisible: canShowCredentials
        }
        ScrollView {
            id: scrollView
            Layout.fillHeight: true
            Layout.fillWidth: true

            Flickable {
                id: flickable
                property double savedScrollPosition
                Layout.fillHeight: true
                Layout.fillWidth: true
                contentWidth: credentialsColumn.width;
                contentHeight: credentialsColumn.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                function restoreScrollPosition() {
                    contentY = flickable.savedScrollPosition
                }

                function saveScrollPosition() {
                    savedScrollPosition = flickable.contentY
                }

                ColumnLayout {
                    width: flickable.width
                    id: credentialsColumn
                    visible: device.hasDevice && (ccidModeMatch || slotModeMatch)
                    anchors.right: appWindow.right
                    anchors.left: appWindow.left
                    anchors.top: appWindow.top
                    spacing: 0

                    Repeater {
                        id: repeater
                        model: filteredCredentials(credentials)
                        property var selected: null
                        property var selectedIndex: null

                        Rectangle {
                            id: credentialRectangle
                            color: getCredentialColor(index, repeater.selected,
                                                      modelData)
                            Layout.fillWidth: true
                            Layout.minimumHeight: 70
                            Layout.alignment: Qt.AlignTop

                            MouseArea {
                                anchors.fill: parent
                                onClicked: handleMouseClick(mouse, index,
                                                            repeater.selected,
                                                            repeater.selectedIndex,
                                                            modelData)
                                acceptedButtons: Qt.RightButton | Qt.LeftButton
                            }

                            ColumnLayout {
                                anchors.leftMargin: 10
                                anchors.topMargin: 5
                                anchors.bottomMargin: 5
                                anchors.fill: parent
                                spacing: 0
                                Label {
                                    visible: hasIssuer(modelData.name)
                                    text: qsTr("") + parseIssuer(modelData.name)
                                    font.pixelSize: 12
                                }
                                Label {
                                    opacity: isExpired(modelData) ? 0.6 : 1
                                    visible: modelData.code !== null
                                    text: qsTr("") + modelData.code
                                    font.family: "Verdana"
                                    font.pixelSize: 20
                                }
                                Label {
                                    text: hasIssuer(
                                              modelData.name) ? qsTr(
                                                                    "") + parseName(
                                                                    modelData.name) : modelData.name
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }
                }
            }
        }

        TextField {
            id: search
            visible: canShowCredentials && device.hasAnyCredentials()
            placeholderText: qsTr("Search...")
            Layout.fillWidth: true
            KeyNavigation.tab: arrowKeys
            Shortcut {
                sequence: StandardKey.Find
                onActivated: search.focus = true
            }
        }
    }

    Timer {
        id: ykTimer
        triggeredOnStart: true
        interval: 500
        repeat: true
        running: true
        onTriggered: device.refresh(refreshDependingOnMode)
    }

    Timer {
        id: timeLeftTimer
        interval: 100
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: checkTimeLeft()
    }

    Timer {
        id: hotpCoolDownTimer
        interval: 5000
        onTriggered: hotpCoolDowns = []
    }

    Timer {
        id: hotpTouchTimer
        interval: 500
        onTriggered: touchYourYubikey.open()
    }

    function checkTimeLeft() {
        var timeLeft = device.expiration - (Date.now() / 1000)
        if (timeLeft <= 0 && timeLeftBar.value > 0) {
            flickable.saveScrollPosition()
            refreshDependingOnMode(true)
        }
        timeLeftBar.value = timeLeft
    }

    function allowManualGenerate(cred) {
        return cred != null && (cred.oath_type === "hotp"
                                || repeater.selected.touch)
    }

    function enableManualGenerate(cred) {
        if (allowManualGenerate(cred)) {
            if (cred.oath_type !== "hotp") {
                return cred.code === null || isExpired(repeater.selected)
            } else {
                return !isInCoolDown(cred.name)
            }
        } else {
            return false
        }
    }

    function isExpired(cred) {
        return cred !== null && (cred.oath_type !== "hotp")
                && (cred.expiration - (Date.now() / 1000) <= 0)
    }

    function rememberPassword() {
        var deviceId = device.oathId
        settings.savedPasswords += deviceId + ':' + device.passwordKey + ';'
    }

    function refreshDependingOnMode(force) {
        if (hasDevice && shouldRefresh) {
            if (settings.slotMode && device.hasOTP) {
                device.refreshSlotCredentials([settings.slot1, settings.slot2],
                                              getSlotDigitsSettings(), force)
            } else if (!settings.slotMode && device.hasCCID) {
                device.refreshCCIDCredentials(force)
            }
        }
    }

    function getSlotDigitsSettings() {
        var slot1digits = settings.slot1digits === 1 ? 8 : 6
        var slot2digits = settings.slot2digits === 1 ? 8 : 6
        return [slot1digits, slot2digits]
    }

    function filteredCredentials(creds) {
        var result = []
        if (creds !== null) {
            for (var i = 0; i < creds.length; i++) {
                var cred = creds[i]
                if (cred.name.toLowerCase().indexOf(search.text.toLowerCase(
                                                        )) !== -1) {
                    result.push(creds[i])
                }
            }
        }

        // Sort credentials based on the
        // full name, including the issuer prefix
        result.sort(function (a, b) {
            return a.name.localeCompare(b.name)
         })

        // If the search gave some results,
        // the top credential should be selected.
        if (result[0] !== null && search.text.length > 0) {
            repeater.selected = result[0]
        } else {
            repeater.selected = null
        }
        return result
    }

    function isInCoolDown(name) {
        return hotpCoolDowns.indexOf(name) !== -1
    }

    function hasIssuer(name) {
        return name.indexOf(':') !== -1
    }

    function parseName(name) {
        return name.split(":").slice(1).join(":")
    }

    function parseIssuer(name) {
        return name.split(":", 1)
    }

    function calculateCredential(credential) {
        if (settings.slotMode) {
            var slot = getSlot(credential.name)
            var digits = getDigits(slot)
            device.calculateSlotMode(slot, digits)
        } else {
            device.calculate(credential)
        }
        if (credential.oath_type === "hotp") {
            hotpTouchTimer.restart()
        }
        if (credential.touch) {
            touchYourYubikey.open()
        }
    }

    function getSlot(name) {
        if (name.indexOf('1') !== -1) {
            return 1
        }
        if (name.indexOf('2') !== -1) {
            return 2
        }
    }

    function getDigits(slot) {
        return getSlotDigitsSettings()[slot - 1]
    }

    function openClearAddCredential() {
        if (settings.slotMode) {
            addCredentialSlot.clear()
            device.getSlotStatus(addCredentialSlot.open)
        } else {
            addCredential.clear()
            addCredential.open()
        }
    }

    function getTitle() {
        return qsTr("Yubico Authenticator") + (settings.slotMode ? qsTr(" [Slot mode]") : '')
    }

    function saveSettings() {
        settings.slotMode = settingsDialog.slotMode
        settings.slot1 = settingsDialog.slot1
        settings.slot2 = settingsDialog.slot2
        settings.slot1digits = settingsDialog.slot1digits
        settings.slot2digits = settingsDialog.slot2digits
    }

    function trySetPassword() {
        if (setPassword.newPassword.length > 0) {
            device.setPassword(setPassword.newPassword)
        } else {
            device.setPassword(null)
        }
    }

    function handleNewDevice() {
        if (device.hasDevice && ccidModeMatch) {
            device.promptOrSkip(passwordPrompt, settings.savedPasswords)
        } else {
            passwordPrompt.close()
            setPassword.close()
            addCredential.close()
            addCredentialSlot.close()
        }
    }

    function handleGenerate(cred) {
        if (!isInCoolDown(cred.name)) {
            calculateCredential(cred)
            if (cred.oath_type === "hotp") {
                hotpCoolDowns.push(cred.name)
                hotpCoolDownTimer.restart()
            }
        }
    }

    function handlePasswordEntered() {
        if (passwordPrompt.remember) {
            device.validate(passwordPrompt.password, rememberPassword)
        } else {
            device.validate(passwordPrompt.password)
        }
        passwordPrompt.clear()
    }

    function deleteSelectedCredential() {
        if (settings.slotMode) {
            device.deleteSlotCredential(getSlot(repeater.selected.name))
        } else {
            device.deleteCredential(repeater.selected)
        }
    }

    function getCredentialColor(index, selected, modelData) {
        if (selected != null && selected.name === modelData.name) {
            return palette.dark
        }
        if (index % 2 == 0) {
            return "#00000000"
        }
        return palette.alternateBase
    }

    function handleMouseClick(mouse, index, selected, selectedIndex, modelData) {

        arrowKeys.forceActiveFocus()

        if (mouse.button & Qt.LeftButton) {
            if (selected !== null && selected.name === modelData.name) {
                // Unselect
                repeater.selected = null
                repeater.selectedIndex = null
            } else {
                // Select
                repeater.selected = modelData
                repeater.selectedIndex = index
            }
        }
        if (mouse.button & Qt.RightButton) {
            repeater.selected = modelData
            repeater.selectedIndex = index
            credentialMenu.popup()
        }
    }
}
