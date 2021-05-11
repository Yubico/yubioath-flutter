import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

StyledExpansionPanel {
    label: qsTr("Reset FIDO")
    //description: qsTr("Delete all saved passwords.")
    isEnabled: false
    visible: settingsPanel.hasPin
    isBottomPanel: true
    toolButtonIcon: "../images/delete.svg"
    toolButtonToolTip: qsTr("Clear")
    toolButton.onClicked: navigator.confirm({
                                      "heading": qsTr("Reset FIDO?"),
                                      "message": qsTr("Are you sure you want to reset FIDO? This will delete all FIDO credentials, including FIDO U2F credentials, and remove the FIDO2 PIN.

                                                      This action cannot be undone!"),
                                      "buttonAccept": qsTr("Reset"),
                                      "acceptedCb": function() {
                                          yubiKey.fidoReset(function (resp) {
                                              if (resp.success) {
                                                  load()
                                                  navigator.snackBar(
                                                              "FIDO applications have been reset")
                                              } else {
                                                  if (resp.error_id === 'touch timeout') {
                                                      navigator.snackBarError(
                                                                  qsTr("A reset requires a touch on the YubiKey to be confirmed."))
                                                  } else {
                                                      navigator.snackBarError(navigator.getErrorMessage(resp.error_id))
                                                  }
                                              }
                                          })}
   })
}
