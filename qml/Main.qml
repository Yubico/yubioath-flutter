import QtQuick 2.6
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
    title: settings.slotMode ? qsTr("Yubico Authenticator [Slot mode]") : qsTr(
                                   "Yubico Authenticator")
    property var device: yk
    property var credentials: device.credentials
    property bool validated: device.validated
    property bool hasDevice: device.hasDevice
    property bool canShowCredentials: hasDevice && ((settings.slotMode
                                                     && device.hasOTP)
                                                    || (!settings.slotMode
                                                        && device.hasCCID))
    property var hotpCoolDowns: []
    property var totpCoolDowns: []

    SystemPalette {
        id: palette
    }

    Settings {
        id: settings
        property bool slotMode
        property bool slot1
        property bool slot2
        property var slot1digits
        property var slot2digits
        property string savedPasswords
    }

    menuBar: MenuBar {

        Menu {
            title: qsTr("File")
            MenuItem {
                text: qsTr('Add credential...')
                onTriggered: {
                    addCredential.clear()
                    addCredential.open()
                }
                shortcut: StandardKey.New
            }
            MenuItem {
                text: qsTr('Set password...')
                enabled: !settings.slotMode
                onTriggered: setPassword.open()
            }
            MenuItem {
                text: qsTr('Reset...')
                enabled: !settings.slotMode
                onTriggered: reset.open()
            }
            MenuItem {
                text: qsTr('Settings')
                onTriggered: settingsDialog.open()
            }
            MenuItem {
                text: qsTr("Exit")
                onTriggered: Qt.quit()
                shortcut: StandardKey.Quit
            }
        }

        Menu {
            title: qsTr("Help")
            MenuItem {
                text: qsTr("About Yubico Authenticator")
                onTriggered: aboutPage.show()
            }
        }
    }

    AboutPage {
        id: aboutPage
    }

    AddCredential {
        id: addCredential
        onAccepted: refreshDependingOnMode(true)
    }

    SettingsDialog {
        id: settingsDialog
        settings: settings
        onAccepted: {
            settings.slotMode = settingsDialog.slotMode
            settings.slot1 = settingsDialog.slot1
            settings.slot2 = settingsDialog.slot2
            settings.slot1digits = settingsDialog.slot1digits
            settings.slot2digits = settingsDialog.slot2digits
            refreshDependingOnMode(true)
        }
    }

    SetPassword {
        id: setPassword
        onAccepted: {
            if (setPassword.newPassword !== setPassword.confirmPassword) {
                noMatch.open()
            } else {
                if (setPassword.newPassword != "") {
                    device.setPassword(setPassword.newPassword)
                } else {
                    device.setPassword(null)
                }
                passwordUpdated.open()
            }
        }
    }

    MessageDialog {
        id: noMatch
        icon: StandardIcon.Critical
        title: qsTr("Passwords does not match")
        text: qsTr("Password confirmation does not match password.")
        standardButtons: StandardButton.Ok
        onAccepted: setPassword.open()
    }

    MessageDialog {
        id: passwordUpdated
        icon: StandardIcon.Information
        title: qsTr("Password set")
        text: qsTr("A new password has been set.")
        standardButtons: StandardButton.Ok
    }

    MessageDialog {
        id: reset
        icon: StandardIcon.Critical
        title: qsTr("Reset OATH functionality")
        text: qsTr("This will delete all OATH credentials stored on the device, and reset the password. This action cannot be undone. Are you sure you want to reset the device?")
        standardButtons: StandardButton.Ok | StandardButton.Cancel
        onAccepted: {
            device.reset()
            device.refreshCredentials()
        }
    }

    onHasDeviceChanged: {
        if (device.hasDevice) {
            if (!settings.slotMode && device.hasCCID) {
                device.promptOrSkip(passwordPrompt, settings.savedPasswords)
            }
        } else {
            passwordPrompt.close()
            addCredential.close()
        }
    }

    PasswordPrompt {
        id: passwordPrompt
        onAccepted: {
            if (passwordPrompt.remember) {
                device.validate(passwordPrompt.password, rememberPassword)
            } else {
                device.validate(passwordPrompt.password)
            }
        }
    }

    function rememberPassword() {
        var deviceId = device.oathId
        settings.savedPasswords += deviceId + ':' + device.passwordKey + ';'
        console.log(settings.savedPasswords)
    }

    onCredentialsChanged: {
        hotpCoolDowns = []
        totpCoolDowns = []
        hotpTouchTimer.stop()
        hotpCoolDownTimer.stop()
        touchYourYubikey.close()
    }

    // @disable-check M301
    YubiKey {
        id: yk
        onError: {
            console.log(error)
        }
        onWrongPassword: {
            passwordPrompt.open()
        }
    }

    Text {
        visible: !device.hasDevice
        id: noLoadedDeviceMessage
        text: if (device.nDevices == 0) {
                  qsTr("No YubiKey detected")
              } else if (device.nDevices == 1) {
                  qsTr("Connecting to YubiKey...")
              } else {
                  qsTr("Multiple YubiKeys detected!")
              }
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        visible: device.hasDevice
        text: if (credentials !== null && filteredCredentials(
                          credentials).length === 0) {
                  qsTr("No credentials found.")
              } else if (settings.slotMode && !device.hasOTP) {
                  qsTr("Authenticator mode is set to YubiKey slots, but the OTP connection mode is not enabled.")
              } else if (!settings.slotMode && !device.hasCCID) {
                  qsTr("Authenticator mode is set to CCID, but the CCID connection mode is not enabled.")
              } else if (credentials == null) {
                  qsTr("Reading credentials...")
              } else {
                  ""
              }
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
    }

    TextEdit {
        id: clipboard
        visible: false
        function setClipboard(value) {
            text = value
            selectAll()
            copy()
        }
    }

    Menu {
        id: credentialMenu
        MenuItem {
            text: qsTr('Copy')
            shortcut: StandardKey.Copy
            onTriggered: {
                if (repeater.selected != null) {
                    clipboard.setClipboard(repeater.selected.code)
                }
            }
        }
        MenuItem {
            visible: allowManualGenerate(repeater.selected)
            enabled: allowManualGenerate(repeater.selected) && !isInCoolDown(
                         repeater.selected.name)
            text: qsTr('Generate code')
            shortcut: "Space"
            onTriggered: {
                if (!isInCoolDown(repeater.selected.name)) {
                    calculateCredential(repeater.selected)
                    if (repeater.selected.oath_type === "hotp") {
                        hotpCoolDowns.push(repeater.selected.name)
                        hotpCoolDownTimer.restart()
                    } else if (repeater.selected.touch) {
                        totpCoolDowns.push(repeater.selected.name)
                    }
                }
            }
        }
        MenuItem {
            text: qsTr('Delete')
            shortcut: StandardKey.Delete
            onTriggered: confirmDeleteCredential.open()
        }
    }

    function allowManualGenerate(cred) {
        return cred != null && (cred.oath_type === "hotp"
                                || repeater.selected.touch)
    }

    MessageDialog {
        id: confirmDeleteCredential
        icon: StandardIcon.Warning
        title: qsTr("Delete credential?")
        text: qsTr("Are you sure you want to delete the credential?")
        standardButtons: StandardButton.Ok | StandardButton.Cancel
        onAccepted: {
            if (settings.slotMode) {
                device.deleteSlotCredential(getSlot(repeater.selected['name']))
            } else {
                device.deleteCredential(repeater.selected)
            }
            refreshDependingOnMode(true)
        }
    }

    MessageDialog {
        id: touchYourYubikey
        icon: StandardIcon.Information
        title: qsTr("Touch your YubiKey")
        text: qsTr("Touch your YubiKey to generate the code.")
        standardButtons: StandardButton.NoButton
    }

    Item {
        id: arrowKeys
        focus: true
        Keys.onUpPressed: {
            if (repeater.selectedIndex == null) {
                repeater.selected = repeater.model[repeater.model.length - 1]
                repeater.selectedIndex = repeater.model.length - 1
            } else if (repeater.selectedIndex > 0) {
                repeater.selected = repeater.model[repeater.selectedIndex - 1]
                repeater.selectedIndex = repeater.selectedIndex - 1
            }
        }
        Keys.onDownPressed: {
            if (repeater.selectedIndex == null) {
                repeater.selected = repeater.model[0]
                repeater.selectedIndex = 0
            } else if (repeater.selectedIndex < repeater.model.length - 1) {
                repeater.selected = repeater.model[repeater.selectedIndex + 1]
                repeater.selectedIndex = repeater.selectedIndex + 1
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ProgressBar {
            id: progressBar
            visible: canShowCredentials
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Layout.maximumHeight: 10
            Layout.minimumHeight: 10
            Layout.minimumWidth: 300
            Layout.fillWidth: true
            maximumValue: 30
            minimumValue: 0

            style: ProgressBarStyle {
                progress: Rectangle {
                    color: "#9aca3c"
                }

                background: Rectangle {
                    color: palette.mid
                }
            }
        }

        ScrollView {
            id: scrollView
            Layout.fillHeight: true
            Layout.fillWidth: true

            ColumnLayout {
                width: scrollView.viewport.width
                id: credentialsColumn
                spacing: 0
                visible: device.hasDevice
                anchors.right: appWindow.right
                anchors.left: appWindow.left
                anchors.top: appWindow.top

                Repeater {
                    id: repeater
                    model: filteredCredentials(credentials)
                    property var selected
                    property var selectedIndex

                    Rectangle {
                        id: credentialRectangle
                        focus: true
                        color: {
                            if (repeater.selected != null) {
                                if (repeater.selected.name == modelData.name) {
                                    return palette.dark
                                }
                            }
                            if (index % 2 == 0) {
                                return "#00000000"
                            }
                            return palette.alternateBase
                        }
                        Layout.fillWidth: true
                        Layout.minimumHeight: 70
                        Layout.alignment: Qt.AlignTop

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                arrowKeys.forceActiveFocus()
                                if (mouse.button & Qt.LeftButton) {
                                    if (repeater.selected != null
                                            && repeater.selected.name == modelData.name) {
                                        repeater.selected = null
                                        repeater.selectedIndex = null
                                    } else {
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
                            acceptedButtons: Qt.RightButton | Qt.LeftButton
                        }

                        ColumnLayout {
                            anchors.leftMargin: 10
                            spacing: -15
                            anchors.fill: parent
                            Text {
                                visible: hasIssuer(modelData.name)
                                text: qsTr('') + parseIssuer(modelData.name)
                                font.pointSize: 13
                            }
                            Text {
                                opacity: isInCoolDown(modelData.name) ? 0.6 : 1
                                visible: modelData.code != null
                                text: qsTr('') + modelData.code
                                font.family: "Verdana"
                                font.pointSize: 22
                            }
                            Text {
                                text: hasIssuer(
                                          modelData.name) ? qsTr(
                                                                '') + parseName(
                                                                modelData.name) : modelData.name
                                font.pointSize: 13
                            }
                        }
                    }
                }
            }
        }

        TextField {
            id: search
            visible: canShowCredentials
            placeholderText: 'Search...'
            Layout.fillWidth: true
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
        id: progressBarTimer
        interval: 100
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            var timeLeft = device.expiration - (Date.now() / 1000)
            if (timeLeft <= 0 && progressBar.value > 0) {
                device.refresh(refreshDependingOnMode)
                totpCoolDowns = []
            }
            progressBar.value = timeLeft
        }
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

    function refreshDependingOnMode(force) {
        if (hasDevice) {
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
        if (creds != null) {
            for (var i = 0; i < creds.length; i++) {
                var cred = creds[i]
                if (cred.name.toLowerCase().indexOf(search.text.toLowerCase(
                                                        )) !== -1) {
                    result.push(creds[i])
                }
            }
        }
        return result
    }

    function isInCoolDown(name) {
        return hotpCoolDowns.indexOf(name) !== -1 || totpCoolDowns.indexOf(
                    name) !== -1
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
        if (credential.oath_type === 'hotp') {
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
}
