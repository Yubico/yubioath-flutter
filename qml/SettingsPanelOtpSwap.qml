import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

StyledExpansionPanel {
    label: qsTr("Swap configuration")
    description: qsTr("Reverse configuration between slots.")
    isEnabled: false
    isVisible: yubiKey.currentDeviceEnabled("OATH")

    toolButtonIcon: "../images/swap.svg"
    toolButtonToolTip: qsTr("Swap configuration between slots")
    toolButton.onClicked: navigator.confirm({
                                      "heading": qsTr("Swap configuration?"),
                                      "message": qsTr("This will swap the configuration between slot 1 and 2."),
                                      "warning": false,
                                      "buttonAccept": qsTr("Swap"),
                                      "acceptedCb": function () {
                                          swapConfigurations()
                                      }
                                })

    function swapConfigurations() {
        yubiKey.swapSlots(function (resp) {
            if (resp.success) {
                otp0.updateCounter++
                otp1.updateCounter++
                navigator.snackBar(
                            qsTr("Configurations swapped between slots"))
            } else {
                if (resp.error_id === 'write error') {
                    snackbarError.show(
                                qsTr("Failed to swap slots. Make sure the YubiKey does not have restricted access."))
                } else {
                    navigator.snackBarError(
                           navigator.getErrorMessage(
                               resp.error_id))
                }
            }
        })
}
}
