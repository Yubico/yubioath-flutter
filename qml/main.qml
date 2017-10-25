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
    signal generate(bool copyAfterGenerate)
    signal deleteCredential

    onDeleteCredential: confirmDeleteCredential.open()
    onGenerate: handleGenerate(selected, copyAfterGenerate)
    onCopy: clipboard.setClipboard(selected.code)

    onHasDeviceChanged: handleNewDevice()

    menuBar: MainMenuBar {
        slotMode: settings.slotMode
        hasDevice: device.hasDevice
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
            visible: canShowCredentials && device.hasAnyCredentials()
        }

        ScrollView {
            id: scrollView
            style: ScrollViewStyle {
                transientScrollBars: true
            }
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

                        Rectangle {
                            id: credentialRectangle
                            color: getCredentialColor(index, modelData)
                            Layout.minimumHeight: {
                                var baseHeight = issuerLbl.height
                                        + codeLbl.height + nameLbl.height + 10
                                return hasCustomTimeBar(
                                            modelData) ? baseHeight
                                                         + 10 : baseHeight
                            }
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop

                            MouseArea {
                                anchors.fill: parent
                                onClicked: handleCredentialSingleClick(
                                               mouse, index, modelData)
                                onDoubleClicked: handleCredentialDoubleClick(
                                                     mouse, index, modelData)
                                acceptedButtons: Qt.RightButton | Qt.LeftButton
                            }

                            ColumnLayout {
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                anchors.topMargin: 5
                                anchors.bottomMargin: 5
                                anchors.fill: parent
                                spacing: 0
                                Label {
                                    id: issuerLbl
                                    visible: modelData.issuer != null
                                             && modelData.issuer.length > 0
                                    text: qsTr("") + modelData.issuer
                                    color: getCredentialTextColor(modelData)
                                }
                                Label {
                                    id: codeLbl
                                    opacity: isExpired(modelData) ? 0.6 : 1
                                    visible: modelData.code !== null
                                    text: qsTr("") + getSpacedCredential(
                                              modelData.code)
                                    font.pointSize: issuerLbl.font.pointSize * 1.8
                                    color: getCredentialTextColor(modelData)
                                }
                                Label {
                                    id: nameLbl
                                    text: modelData.name
                                    color: getCredentialTextColor(modelData)
                                }
                                Timer {
                                    id: customTimer
                                    interval: 100
                                    repeat: true
                                    running: hasCustomTimeBar(modelData)
                                    triggeredOnStart: true
                                    onTriggered: {
                                        var timeLeft = modelData.expiration - (Date.now() / 1000)
                                        if (timeLeft <= 0
                                                && customTimeLeftBar.value > 0) {
                                            refreshDependingOnMode(true)
                                        }
                                        customTimeLeftBar.value = timeLeft
                                    }
                                }
                                ProgressBar {
                                    id: customTimeLeftBar
                                    visible: hasCustomTimeBar(modelData)
                                    Layout.topMargin: 3
                                    Layout.fillWidth: true
                                    Layout.minimumHeight: 7
                                    Layout.maximumHeight: 7
                                    Layout.alignment: Qt.AlignBottom
                                    maximumValue: modelData.period
                                    rotation: 180
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
            Keys.onEscapePressed: {
                search.text = ""
                arrowKeys.focus = true
                deselectCredential()
            }
            Keys.onReturnPressed: generateOrCopy()
            Keys.onEnterPressed: generateOrCopy()
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

    NoQrDialog {
        id: noQr
    }

    function deselectCredential() {
        selected = null
        selectedIndex = null
    }

    function hasCustomTimeBar(modelData) {
        return modelData.period !== 30 && (modelData.oath_type === 'totp' || modelData.touch)
    }

    function getSpacedCredential(code) {
        // Add a space in the code for easier reading.
        if (code != null) {
            switch (code.length) {
            case 6:
                // 123 123
                return code.slice(0, 3) + " " + code.slice(3)
            case 7:
                // 1234 123
                return code.slice(0, 4) + " " + code.slice(4)
            case 8:
                // 1234 1234
                return code.slice(0, 4) + " " + code.slice(4)
            default:
                return code
            }
        }
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
                return !isInCoolDown(cred.long_name)
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

    function filteredCredentials(creds) {
        var searchResult = []
        if (creds !== null) {
            for (var i = 0; i < creds.length; i++) {
                var cred = creds[i]
                if (cred.long_name.toLowerCase().indexOf(search.text.toLowerCase(
                                                        )) !== -1) {
                    searchResult.push(cred)
                }
            }
        }

        // Sort credentials based on the
        // full name, including the issuer prefix
        searchResult.sort(function (a, b) {
            return a.long_name.localeCompare(b.long_name)
        })

        // If the search gave some results,
        // the top credential should be selected.
        if (searchResult[0] !== null && search.text.length > 0) {
            selected = searchResult[0]
        } else if (search.text.length > 0) {
            // If search was started but no result,
            // reset selected to avoid hidden selected creds.
            deselectCredential()
        }
        return searchResult
    }

    function isInCoolDown(longName) {
        return hotpCoolDowns.indexOf(longName) !== -1
    }

    function calculateCredential(credential, copyAfterUpdate) {
        flickable.saveScrollPosition()

        if (settings.slotMode) {
            var slot = getSlot(credential.name)
            var digits = getDigits(slot)
            device.calculateSlotMode(slot, digits, copyAfterUpdate)
        } else {
            device.calculate(credential, copyAfterUpdate)
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

    function handleGenerate(cred, copyAfterUpdate) {
        if (!isInCoolDown(cred.long_name)) {
            calculateCredential(cred, copyAfterUpdate)
            if (cred.oath_type === "hotp") {
                hotpCoolDowns.push(cred.long_name)
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
        if (selected != null && selected.long_name === modelData.long_name) {
            return palette.highlight
        }
        if (index % 2 == 0) {
            return palette.window
        }
        return palette.midlight
    }

    function getCredentialTextColor(modelData) {
        if (selected != null && selected.long_name === modelData.long_name) {
            return palette.highlightedText
        } else {
            return palette.windowText
        }
    }

    function handleCredentialSingleClick(mouse, index, modelData) {

        arrowKeys.forceActiveFocus()

        // Left click, select or deselect credential.
        if (mouse.button & Qt.LeftButton) {
            if (selected != null && selected.long_name === modelData.long_name) {
                deselectCredential()
            } else {
                selected = modelData
                selectedIndex = index
            }
        }

        // Right-click, select credential and open popup menu.
        if (mouse.button & Qt.RightButton) {
            selected = modelData
            selectedIndex = index
            credentialMenu.popup()
        }
    }

    function handleCredentialDoubleClick(mouse, index, modelData) {

        arrowKeys.forceActiveFocus()

        // A double-click should select the credential,
        // then generate if needed and copy the code.
        selected = modelData
        selectedIndex = index
        generateOrCopy()
    }

    function generateOrCopy() {
        if (selected.code == null || isExpired(selected) || selected.oath_type === 'hotp') {
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
