import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

StyledExpansionPanel {
    label: qsTr("Reset")
    description: qsTr("Warning: Reset will delete all accounts and restore factory defaults.")
    isEnabled: false
    isVisible: yubiKey.currentDeviceEnabled("OATH")

    toolButtonIcon: "../images/reset.svg"
    toolButtonToolTip: qsTr("Reset device")
    toolButton.onClicked: navigator.confirm({
                                      "heading": qsTr("Reset device?"),
                                      "message": qsTr("This will delete all accounts and restore factory defaults of your YubiKey."),
                                      "description": qsTr("Before proceeding:<ul style=\"-qt-list-indent: 1;\"><li>There is NO going back after a factory reset.<li>If you do not know what you are doing, do NOT do this.</ul>"),
                                      "buttonAccept": qsTr("Reset device"),
                                      "acceptedCb": function () {
                                          navigator.goToLoading()
                                          yubiKey.reset(function (resp) {
                                              if (resp.success) {
                                                  entries.clear()
                                                  navigator.snackBar(
                                                              qsTr("Reset completed"))
                                                  yubiKey.currentDevice.hasPassword = false
                                              } else {
                                                  navigator.snackBarError(
                                                              navigator.getErrorMessage(
                                                                  resp.error_id))
                                                  console.log("reset failed:",
                                                              resp.error_id)
                                                  if (resp.error_id === 'no_device_custom_reader') {
                                                      yubiKey.clearCurrentDeviceAndEntries()
                                                  }
                                              }

                                              navigator.goToYubiKey()
                                          })
                                      }
   })
}
