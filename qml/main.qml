import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.2
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

    property var selected: null
    property var selectedIndex: null

    // Don't refresh credentials when window is minimized or hidden
    // See http://doc.qt.io/qt-5/qwindow.html#Visibility-enum
    property bool shouldRefresh: visibility != 3 && visibility != 0

    signal copy
    signal generate
    signal deleteCredential

    onDeleteCredential: confirmDeleteCredential.open()
    onGenerate: handleGenerate(selected)
    onCopy: clipboard.setClipboard(selected.code)

    onHasDeviceChanged: handleNewDevice()

    menuBar: MainMenuBar {
        slotMode: settings.slotMode
        hasDevice: device.hasDevice
        credential: selected
        enableGenerate: enableManualGenerate(selected)
        onOpenAddCredential: openClearAddCredential()
        onOpenSetPassword: setPassword.open()
        onOpenReset: reset.open()
        onOpenSettings: settingsDialog.open()
        onOpenAbout: aboutPage.open()
    }

    Component.onCompleted: {
        updateTrayVisability()
        ensureValidWindowPosition()
    }

    Component.onDestruction: saveScreenLayout()

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
        property bool closeToTray

        // Keep track of window and desktop dimensions.
        property alias width: appWindow.width
        property alias height: appWindow.height
        property alias x: appWindow.x
        property alias y: appWindow.y
        property var desktopAvailableWidth
        property var desktopAvailableHeight

        onCloseToTrayChanged: {
            updateTrayVisability()
        }
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
        onCredentialsRefreshed: {
            flickable.restoreScrollPosition()
            hotpTouchTimer.stop()
            touchYourYubikey.close()
        }
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
        credential: selected
        showGenerate: allowManualGenerate(selected)
        enableGenerate: enableManualGenerate(selected)
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

            MouseArea {
                // A mouse area to allow a click
                // outside search bar to remove focus from it.
                anchors.fill: parent
                onClicked: arrowKeys.focus = true
            }

            Flickable {
                id: flickable
                property double savedScrollPosition
                Layout.fillHeight: true
                Layout.fillWidth: true
                contentWidth: credentialsColumn.width
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
                    visible: device.hasDevice && (ccidModeMatch
                                                  || slotModeMatch)
                    anchors.right: appWindow.right
                    anchors.left: appWindow.left
                    anchors.top: appWindow.top
                    spacing: 0

                    Repeater {
                        id: repeater
                        model: filteredCredentials(credentials)

                        Rectangle {
                            id: credentialRectangle
                            color: getCredentialColor(index, modelData)
                            Layout.fillWidth: true
                            Layout.minimumHeight: 70
                            Layout.alignment: Qt.AlignTop

                            MouseArea {
                                anchors.fill: parent
                                onClicked: handleMouseClick(mouse, index,
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
                                    color: getCredentialTextColor(modelData)
                                }
                                Label {
                                    opacity: isExpired(modelData) ? 0.6 : 1
                                    visible: modelData.code !== null
                                    text: qsTr("") + modelData.code
                                    font.pixelSize: 20
                                    color: getCredentialTextColor(modelData)
                                }
                                Label {
                                    text: hasIssuer(
                                              modelData.name) ? qsTr("") + parseName(
                                                                    modelData.name) : modelData.name
                                    font.pixelSize: 12
                                    color: getCredentialTextColor(modelData)
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

    function saveScreenLayout() {
        settings.desktopAvailableWidth = Screen.desktopAvailableWidth
        settings.desktopAvailableHeight = Screen.desktopAvailableHeight
    }

    function ensureValidWindowPosition() {
        // If we have the same desktop dimensions as last time, use the saved position.
        // If not, put the window in the middle of the screen.
        var savedScreenLayout = (settings.desktopAvailableWidth === Screen.desktopAvailableWidth)
                && (settings.desktopAvailableHeight === Screen.desktopAvailableHeight)
        appWindow.x = (savedScreenLayout) ? settings.x : Screen.width / 2 - appWindow.width / 2
        appWindow.y = (savedScreenLayout) ? settings.y : Screen.height / 2 - appWindow.height / 2
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
        return cred != null && (cred.oath_type === "hotp" || selected.touch)
    }

    function enableManualGenerate(cred) {
        if (allowManualGenerate(cred)) {
            if (cred.oath_type !== "hotp") {
                return cred.code === null || isExpired(selected)
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
        var entries = getPasswordEntries()
        entries[deviceId] = device.passwordKey
        savePasswordEntries(entries)
    }

    function refreshDependingOnMode(force) {
        if (hasDevice && shouldRefresh) {
            if (settings.slotMode && device.hasOTP) {
                device.validated = true // Slot side has no password function
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
                    result.push(cred)
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
            selected = result[0]
        } else if (search.text.length > 0) {
            // If search was started but no result,
            // reset selected to avoid hidden selected creds.
            selected = null
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
        flickable.saveScrollPosition()

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
        settings.closeToTray = settingsDialog.closeToTray
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
            device.promptOrSkip(passwordPrompt)
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
            device.validate(passwordPrompt.password, null)
        }
    }

    function deleteSelectedCredential() {
        if (settings.slotMode) {
            device.deleteSlotCredential(getSlot(selected.name))
        } else {
            device.deleteCredential(selected)
        }
    }

    function getCredentialColor(index, modelData) {
        if (selected != null && selected.name === modelData.name) {
            return palette.highlight
        }
        if (index % 2 == 0) {
            return palette.window
        }
        return palette.midlight
    }

    function getCredentialTextColor(modelData) {
        if (selected != null && selected.name === modelData.name) {
            return palette.highlightedText
        } else {
            return palette.windowText
        }
    }

    function handleMouseClick(mouse, index, modelData) {

        arrowKeys.forceActiveFocus()

        if (mouse.button & Qt.LeftButton) {
            if (selected != null && selected.name === modelData.name) {
                // Unselect
                selected = null
                selectedIndex = null
            } else {
                // Select
                selected = modelData
                selectedIndex = index
            }
        }
        if (mouse.button & Qt.RightButton) {
            selected = modelData
            selectedIndex = index
            credentialMenu.popup()
        }
    }

    function updateTrayVisability() {
        SysTrayIcon.visible = settings.closeToTray
        // When the tray option is enabled, closing the last window
        // doesn't actually close the application.
        app.quitOnLastWindowClosed = !settings.closeToTray
    }

    function getPasswordEntries() {
        // Try to parse the saved password (if any) from the settings.
        // If no saved passwords or the format is wrong,
        // just return an empty object.
        var entries = {

        }
        if (settings.savedPasswords.length !== 0) {
            try {
                entries = JSON.parse(settings.savedPasswords)
            } catch (e) {
                console.log("Could not read passwords.", e)
            }
        }
        return entries
    }

    function savePasswordEntries(entries) {
        try {
            settings.savedPasswords = JSON.stringify(entries)
        } catch (e) {
            console.log("Could not save password.", e)
        }
    }
}
