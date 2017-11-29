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
    title: getTitle()
    property var device: yk
    property var credentials: device.entries
    property bool hasDevice: device.hasDevice
    property bool canShowCredentials: device.hasDevice && modeAndKeyMatch
                                      && device.validated
    property bool modeAndKeyMatch: slotModeMatch || ccidModeMatch
    property bool slotModeMatch: (settings.slotMode && device.hasOTP)
    property bool ccidModeMatch: (!settings.slotMode && device.hasCCID)
    property var hotpCoolDowns: []

    property var selectedKey: null

    // Don't refresh credentials when window is minimized or hidden
    // See http://doc.qt.io/qt-5/qwindow.html#Visibility-enum
    property bool shouldRefresh: visibility != 3 && visibility != 0

    property bool hideOnLaunch: settings.closeToTray && settings.hideOnLaunch

    property bool displayTimersRunning: device.hasDevice && appWindow.visible

    signal copy
    signal generate(bool copyAfterGenerate)
    signal deleteCredential

    onDeleteCredential: confirmDeleteCredential.open()
    onGenerate: handleGenerate(getSelected(), copyAfterGenerate)
    onCopy: clipboard.setClipboard(getSelected().code.value)

    onHasDeviceChanged: handleNewDevice()

    menuBar: MainMenuBar {
        slotMode: settings.slotMode
        hasDevice: device.hasDevice
        enableGenerate: enableManualGenerate(getSelected())
        onOpenAddCredential: openClearAddCredential()
        onOpenSetPassword: setPassword.open()
        onOpenReset: reset.open()
        onOpenSettings: settingsDialog.open()
        onOpenAbout: aboutPage.open()
    }

    Component.onCompleted: {
        settings.savedPasswords = ""  //No longer used.
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

    BusyIndicator {
        id: busy
        z: 1
        running: false
        anchors.centerIn: parent
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
        property bool hideOnLaunch

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
        device: yk
        slotMode: settings.slotMode
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
            credentials = device.entries
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
        settings: settings
    }

    ClipBoard {
        id: clipboard
    }

    CredentialMenu {
        id: credentialMenu
        credential: getSelected()
        showGenerate: allowManualGenerate(credential)
        enableGenerate: enableManualGenerate(credential)
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
            visible: canShowCredentials && device.hasAnyCredentials()
        }

        ScrollView {
            id: scrollView
            Layout.fillHeight: true
            Layout.fillWidth: true

            MouseArea {
                // A mouse area to allow a click
                // outside search bar to remove focus from it.
                anchors.fill: parent
                onClicked: {
                    arrowKeys.focus = true
                    deselectCredential()
                }
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

                        CredentialItem {
                            code: modelData.code
                            credential: modelData.credential
                            isExpired: appWindow.isExpired(modelData)
                            isSelected: appWindow.isSelected(modelData.credential)
                            timerRunning: displayTimersRunning
                            unselectedColor: (index % 2 == 0
                                ? palette.window
                                : palette.midlight
                            )

                            onDoubleClick: {
                                arrowKeys.forceActiveFocus()

                                // A double-click should select the credential,
                                // then generate if needed and copy the code.
                                selectCredential(modelData)
                                generateOrCopy()
                            }

                            onRefresh: refreshDependingOnMode(force)

                            onSingleClick: {
                                arrowKeys.forceActiveFocus()

                                // Left click, select or deselect credential.
                                if (mouse.button & Qt.LeftButton) {
                                    if (appWindow.isSelected(modelData.credential)) {
                                        deselectCredential()
                                    } else {
                                        selectCredential(modelData)
                                    }
                                }

                                // Right-click, select credential and open popup menu.
                                if (mouse.button & Qt.RightButton) {
                                    selectCredential(modelData)
                                    credentialMenu.popup()
                                }
                            }
                        }
                    }
                }
            }
        }

        TextField {
            id: search
            focus: true
            visible: canShowCredentials && device.hasAnyCredentials()
            placeholderText: qsTr("Search...")
            Layout.fillWidth: true
            KeyNavigation.tab: arrowKeys
            Shortcut {
                sequence: StandardKey.Find
                onActivated: search.forceActiveFocus()
            }
            onTextChanged: selectFirstSearchResult()
            Keys.onEscapePressed: {
                search.text = ""
                arrowKeys.focus = true
                deselectCredential()
            }
            Keys.onReturnPressed: generateOrCopy()
            Keys.onEnterPressed: generateOrCopy()
            Keys.onDownPressed: arrowKeys.goDown()
            Keys.onUpPressed: arrowKeys.goUp()
        }
    }

    Timer {
        id: ykTimer
        triggeredOnStart: true
        interval: 500
        repeat: true
        running: appWindow.visible
        onTriggered: device.refresh(settings.slotMode, refreshDependingOnMode)
    }

    Timer {
        id: timeLeftTimer
        interval: 100
        repeat: true
        running: displayTimersRunning
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

    NoQrDialog {
        id: noQr
    }

    function selectCredential(entry) {
        selectedKey = entry.credential.key
    }

    function deselectCredential() {
        selectedKey = null
    }

    function getSelected() {
        return credentials.find(function(entry) {
            return isSelected(entry.credential)
        }) || null
    }

    function isSelected(credential) {
        return credential.key === selectedKey
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
            refreshDependingOnMode(true)
        }
        timeLeftBar.value = timeLeft
    }

    function allowManualGenerate(entry) {
        var cred = entry && entry.credential
        return cred != null && (cred.oath_type === "HOTP" || cred.touch)
    }

    function enableManualGenerate(entry) {
        var cred = entry && entry.credential
        if (allowManualGenerate(entry)) {
            if (cred.oath_type !== "HOTP") {
                return entry.code === null || isExpired(entry)
            } else {
                return !isInCoolDown(cred.key)
            }
        } else {
            return false
        }
    }

    function isExpired(entry) {
        return entry !== null && entry.code !== null && (entry.credential.oath_type !== "HOTP")
                && (entry.code.valid_to - (Date.now() / 1000) <= 0)
    }

    function refreshDependingOnMode(force) {
        if (hasDevice && shouldRefresh) {
            flickable.saveScrollPosition()
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
        var slot1digits = 6
        if (settings.slot1digits === 1) {
            slot1digits = 7
        }
        if (settings.slot1digits === 2) {
            slot1digits = 8
        }
        var slot2digits = 6
        if (settings.slot2digits === 1) {
            slot2digits = 7
        }
        if (settings.slot2digits === 2) {
            slot2digits = 8
        }
        return [slot1digits, slot2digits]
    }

    function filteredCredentials(entries) {
        var searchResult = []
        if (entries !== null) {
            for (var i = 0; i < entries.length; i++) {
                var entry = entries[i]
                if (entry.credential.key.toLowerCase().indexOf(search.text.toLowerCase(
                                                        )) !== -1) {
                    searchResult.push(entry)
                }
            }
        }

        return searchResult
    }

    function selectFirstSearchResult() {
        var searchResult = filteredCredentials(credentials)
        if (search.text.length > 0) {
            if (searchResult[0] != null) {
                if (false === searchResult.some(function(entry) { return isSelected(entry.credential) })) {
                    // If search does not include current selection,
                    // reset selected to avoid hidden selected creds.
                    deselectCredential()
                }
                if (selectedKey === null) {
                    // If the search gave some results, and nothing is currently selected,
                    // the top credential should be selected.
                    selectCredential(searchResult[0])
                }
            } else {
                // If search was started but no result,
                // reset selected to avoid hidden selected creds.
                deselectCredential()
            }
        }
    }

    function isInCoolDown(longName) {
        return hotpCoolDowns.indexOf(longName) !== -1
    }

    function calculateCredential(entry, copyAfterUpdate) {
        flickable.saveScrollPosition()

        if (settings.slotMode) {
            var slot = getSlot(entry.credential.name)
            var digits = getDigits(slot)
            device.calculateSlotMode(slot, digits, copyAfterUpdate)
        } else {
            device.calculate(entry, copyAfterUpdate)
        }
        if (entry.credential.oath_type === "HOTP") {
            hotpTouchTimer.restart()
        }
        if (entry.credential.touch) {
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
        settings.hideOnLaunch = settingsDialog.closeToTray && settingsDialog.hideOnLaunch
    }

    function trySetPassword() {
        if (setPassword.newPassword.length > 0) {
            device.setPassword(setPassword.newPassword, setPassword.remember)
        } else {
            device.setPassword(null, true)
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

    function handleGenerate(entry, copyAfterUpdate) {
        if (!isInCoolDown(entry.credential.key)) {
            calculateCredential(entry, copyAfterUpdate)
            if (entry.credential.oath_type === "HOTP") {
                hotpCoolDowns.push(entry.credential.key)
                hotpCoolDownTimer.restart()
            }
        }
    }

    function handlePasswordEntered() {
        device.validate(passwordPrompt.password, passwordPrompt.remember)
    }

    function deleteSelectedCredential() {
        if (settings.slotMode) {
            device.deleteSlotCredential(getSlot(getSelected().credential.name))
        } else {
            device.deleteCredential(getSelected().credential)
        }
    }

    function generateOrCopy() {
        var selected = getSelected()
        if (selected.code == null || isExpired(selected) || selected.credential.oath_type === 'HOTP') {
            generate(true)
        } else {
            copy()
        }
    }

    function updateTrayVisability() {
        SysTrayIcon.visible = settings.closeToTray
        // When the tray option is enabled, closing the last window
        // doesn't actually close the application.
        app.quitOnLastWindowClosed = !settings.closeToTray
    }

    function scanQr() {
        busy.running = true
        device.parseQr(ScreenShot.capture(), function (uri) {
            busy.running = false
            if (settings.slotMode && uri) {
                addCredentialSlot.updateForm(uri)
                device.getSlotStatus(addCredentialSlot.open)
            } else if (!settings.slotMode && uri) {
                addCredential.updateForm(uri)
                addCredential.open()
            } else {
                noQr.open()
            }
        })
    }
}
