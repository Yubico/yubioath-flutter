import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import QtQuick.Controls.Material 2.2

ColumnLayout {
    property bool changed: secretKeyInput.text !== ""


    RowLayout {
        StyledTextField {
            id: secretKeyInput
            labelText: qsTr("Secret key")
            validator: validator
        }
    }

    RowLayout {
        StyledComboBox {
            id: digitsCb
            label: qsTr("Digits")
            model: [6, 8]
        }
    }

    RegExpValidator {
        id: validator
        regExp: /[ 2-7a-zA-Z]+=*/
    }

    function programOathHotp(slot) {
        yubiKey.programOathHotp(slot, secretKeyInput.text,
                                digitsCb.currentText, function (resp) {
                                    if (resp.success) {
                                        navigator.snackBar(
                                                    qsTr("Configured OATH-HOTP credential"))
                                    } else {
                                        if (resp.error_id === 'write error') {
                                            navigator.snackBar(qsTr("Failed to modify. Make sure the YubiKey does not have restricted access."))
                                        } else {
                                            navigator.snackBarError(
                                                        navigator.getErrorMessage(
                                                            resp.error_id))
                                        }
                                    }
                                })
    }
}


