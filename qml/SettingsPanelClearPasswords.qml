import QtGraphicalEffects 1.0
import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import QtQuick.Layouts 1.3

StyledExpansionPanel {
    label: qsTr("Clear passwords")
    description: qsTr("Delete all saved passwords.")
    isEnabled: false
    isBottomPanel: true
    toolButtonIcon: "../images/delete.svg"
    toolButtonToolTip: qsTr("Clear")
    toolButton.onClicked: navigator.confirm({
        "heading": qsTr("Clear passwords?"),
        "message": qsTr("This will delete all saved passwords."),
        "description": qsTr("A password prompt will appear the next time a YubiKey with a password is used."),
        "buttonAccept": qsTr("Clear passwords"),
        "acceptedCb": function() {
            yubiKey.clearLocalPasswords(function(resp) {
                if (resp.success)
                    navigator.snackBar(qsTr("Passwords cleared"));

            });
        }
    })
}
