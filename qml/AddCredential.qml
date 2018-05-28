import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2
import "utils.js" as Utils

DefaultDialog {
    id: newCredentialDialog
    title: qsTr("New credential")
    modality: Qt.ApplicationModal
    property var device
    visible: false

    property bool showValidationError: false

    ColumnLayout {
        anchors.fill: parent

        GridLayout {
            columns: 2
            Label {
                text: qsTr("Issuer")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.fillWidth: false
            }
            TextField {
                id: issuer
                Layout.fillWidth: true
                focus: true
                KeyNavigation.tab: name
                Keys.onEscapePressed: close()
                onAccepted: tryAddCredential()
            }
            Label {
                text: qsTr("Account name")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                Layout.fillWidth: false
            }
            TextField {
                id: name
                Layout.fillWidth: true
                KeyNavigation.tab: key
                Keys.onEscapePressed: close()
                onAccepted: tryAddCredential()
            }

            Label {
                text: qsTr("Secret key")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            TextField {
                id: key
                Layout.fillWidth: true
                validator: RegExpValidator {
                    regExp: /[2-7a-zA-Z ]+=*/
                }
                Keys.onEscapePressed: close()
                onAccepted: tryAddCredential()
                KeyNavigation.tab: oathType
            }
            Label {
                text: qsTr("Type")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            GridLayout {
                columns: 3
                ComboBox {
                    id: oathType
                    Layout.fillWidth: true
                    currentIndex: 0
                    model: ['Time based', 'Counter based']
                    KeyNavigation.tab: algorithm
                    Keys.onEscapePressed: close()
                }
                Label {
                    text: qsTr("Algorithm")
                }
                ComboBox {
                    id: algorithm
                    currentIndex: 0
                    Layout.fillWidth: true
                    model: ['SHA-1', 'SHA-256']
                    KeyNavigation.tab: period
                    Keys.onEscapePressed: close()
                }
            }
            Label {
                text: qsTr("Period")
                enabled: oathType.currentIndex === 0
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            }
            GridLayout {
                columns: 3
                id: grid
                SpinBox {
                    Layout.fillWidth: false
                    id: period
                    enabled: oathType.currentIndex === 0
                    Layout.fillHeight: true
                    Layout.preferredWidth: oathType.width
                    value: 30
                    maximumValue: 99
                    minimumValue: 1
                    KeyNavigation.tab: digits
                    Keys.onEscapePressed: close()
                }
                Label {
                    text: qsTr("Digits")
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                }
                ComboBox {
                    id: digits
                    Layout.preferredWidth: algorithm.width
                    currentIndex: 0
                    model: ['6', '7', '8']
                    KeyNavigation.tab: touch
                    Keys.onEscapePressed: close()
                }
            }
            Label {
                text: qsTr("Require touch")
                enabled: enableTouchOption()
                Layout.alignment: Qt.AlignRight
            }
            CheckBox {
                id: touch
                enabled: enableTouchOption()
                KeyNavigation.tab: addCredentialBtn
                Keys.onEscapePressed: close()
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom
            Button {
                id: cancelBtn
                text: qsTr("Cancel")
                onClicked: close()
                Keys.onEscapePressed: close()
                KeyNavigation.tab: issuer
            }
            Button {
                id: addCredentialBtn
                text: qsTr("Save credential")
                enabled: acceptableInput()
                Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                onClicked: tryAddCredential()
                KeyNavigation.tab: cancelBtn
                Keys.onEscapePressed: close()
                isDefault: true
            }
        }

        Label {
            color: 'red'
            font.italic: true
            text: getValidationErrorMessage() || ''
            visible: showValidationError
        }
    }

    MessageDialog {
        id: paddingError
        icon: StandardIcon.Critical
        title: qsTr("Wrong padding")
        text: qsTr("The padding of the key is incorrect.")
        standardButtons: StandardButton.Ok
    }

    MessageDialog {
        id: spaceError
        icon: StandardIcon.Critical
        title: qsTr("No space")
        text: qsTr("There is no storage space left on the device, so the credential can not be added.")
        standardButtons: StandardButton.Ok
    }

    MessageDialog {
        id: confirmOverWrite
        icon: StandardIcon.Warning
        title: qsTr("Overwrite credential?")
        text: qsTr("A credential with this name already exists. Are you sure you want to overwrite this credential?")
        standardButtons: StandardButton.Ok | StandardButton.Cancel
        onAccepted: addCredential()
    }

    function clear() {
        issuer.text = ""
        name.text = ""
        key.text = ""
        oathType.currentIndex = 0
        algorithm.currentIndex = 0
        period.value = 30
        digits.currentIndex = 0
        touch.checked = false
    }

    function tryAddCredential() {
        if (acceptableInput()) {
            showValidationError = false
            if (device.credentialExists(name.text)) {
                confirmOverWrite.open()
            } else {
                addCredential()
            }
        } else {
            showValidationError = true
        }
    }

    function enableTouchOption() {
        return Utils.versionGE(device.version, 4, 2, 6)
    }

    function getValidationErrorMessage() {
        if (name.text.length === 0) {
            return 'Account name must not be empty.'
        } else if (key.text.length === 0) {
            return 'Secret key must not be empty.'
        } else if (name.text.length + issuer.text.length > 60) {
            return 'Issuer and account name combined must be 60 characters or shorter.'
        }
    }

    function acceptableInput() {
        return getValidationErrorMessage() === undefined
    }

    function getAlgoIndex(algo) {
        if (algo === null || algo === 'SHA1') {
            return 0
        }
        if (algo === 'SHA256') {
            return 1
        }
    }

    function getTypeIndex(type) {
        if (type === null || type === 'TOTP') {
            return 0
        }
        if (type === 'HOTP') {
            return 1
        }
    }

    function getDigitsIndex(digits) {
        if (digits === null || digits === 6) {
            return 0
        }
        if (digits === 7) {
            return 1
        }
        if (digits === 8) {
            return 2
        }
    }

    function updateForm(uri) {
        var hasIssuerInName = uri.name.indexOf(':') !== -1
        if (hasIssuerInName) {
            var parsedName = uri.name.split(":").slice(1).join(":")
            var parsedIssuer = uri.name.split(":", 1)[0]
        }
        var hasIssuerSameAsParsed = uri.issuer && uri.issuer === parsedIssuer
        if (hasIssuerInName && (hasIssuerSameAsParsed || !uri.issuer)) {
            name.text = parsedName
        } else {
            name.text = uri.name
        }
        issuer.text = uri.issuer || parsedIssuer || ''
        key.text = uri.secret
        period.value = uri.period || 30
        oathType.currentIndex = getTypeIndex(uri.oath_type)
        algorithm.currentIndex = getAlgoIndex(uri.algorithm)
        digits.currentIndex = getDigitsIndex(uri.digits)
    }

    function addCredential() {

        function errorHandling(error) {
            if (error === 'Incorrect padding') {
                paddingError.open()
            }
            if (error === 'No space') {
                spaceError.open()
            }
            close()
            refreshDependingOnMode(true)
        }

        var _name = name.text
        var _key = key.text
        var _issuer = issuer.text
        var _oathType = oathType.currentIndex === 0 ? 'TOTP' : 'HOTP'
        var _algo = algorithm.currentIndex === 0 ? 'SHA1' : 'SHA256'
        var _digits = digits.currentText
        var _period = period.value
        var _touch = touch.checked

        device.addCredential(_name, _key, _issuer, _oathType, _algo, _digits,
                             _period, _touch, errorHandling)
    }
}
