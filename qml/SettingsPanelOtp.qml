import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

StyledExpansionPanel {
    id: otpConfigurationPanel
    label: slot === 0 ? qsTr("Short touch (slot 1)") : qsTr("Long touch (slot 2)")
    description: updateCounter && isSlotConfigured(slot) ? qsTr("Slot is programmed") : qsTr("Slot is empty")
    isVisible: yubiKey.currentDeviceEnabled("OATH")

    property int slot: 1
    property int updateCounter: 1

    property bool credentialTypeYubicoOTP: credentialTypeCombobox.currentIndex === 1
    property bool credentialTypeChallengeResponse: credentialTypeCombobox.currentIndex === 2
    property bool credentialTypeStaticPassword: credentialTypeCombobox.currentIndex === 3
    property bool credentialTypeOATHHOTP: credentialTypeCombobox.currentIndex === 4
    property bool slotConfigured

    function isSlotConfigured(slot) {
        yubiKey.slotsStatus(function (resp) {
            if (resp.success) {
                slotConfigured = resp.status[slot]
            } else {
                if (resp.error_id === 'timeout') {
                    navigator.snackBarError(qsTr("Failed to load OTP application"))
                } else {
                    navigator.snackBarError(
                                navigator.getErrorMessage(
                                    resp.error_id))
                }
                navigator.home()
            }
        })
        return slotConfigured
    }

    function confirmDelete() {
        navigator.confirm({
            "heading": qsTr("Delete configuration?"),
            "message": qsTr("Do you want to delete the content of %1? This permanently deletes the configuration.").arg(label),
            "acceptedCb": function () {
                yubiKey.eraseSlot(slot+1, function (resp) {
                    if (resp.success) {
                        updateCounter++
                        navigator.snackBar(qsTr("Configured interfaces"))
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
        })
    }


    function getComboBoxIndex(digits) {
        switch (digits) {
        case 0:
            return 0
        case 6:
            return 1
        case 7:
            return 2
        case 8:
            return 3
        default:
            return 0
        }
    }


    ColumnLayout {

        StyledComboBox {
            id: credentialTypeCombobox
            noDefaultSelection: true
            label: qsTr("Credential type")
            model: ["", qsTr("Yubico OTP"), qsTr("Challenge response"), qsTr("Static password"), qsTr("OATH-HOTP")]

            function getCurrentLabel() {
                switch (credentialTypeCombobox.currentIndex) {
                case 1:
                    return qsTr("A Yubico OTP is a 44-character, one use, secure, 128-bit encrypted Public ID and Password.")
                case 2:
                    return qsTr("YubiKey creates a \"response\" based on a provided \"challenge\" and a shared secret.")
                case 3:
                    return qsTr("Store a long static password on the YubiKey so you don't have to remember it.")
                case 4:
                    return qsTr("OATH-HOTP is a standard algorithm for calculating one-time passwords based on a secret and a counter.")
                default:
                    return qsTr("Select credential type to program slot with.")
                }
            }
        }

        Label {
            Layout.fillWidth: true
            font.pixelSize: 12
            color: primaryColor
            opacity: lowEmphasis
            text: credentialTypeCombobox.getCurrentLabel()
            wrapMode: Text.WordWrap
            Layout.rowSpan: 1
            bottomPadding: 8
        }
    }


    ColumnLayout {
        visible: otpConfigurationPanel.credentialTypeYubicoOTP
        Layout.rightMargin: -12

        SettingsPanelYubicoOtp{ id: yubicoOTP}

    }

    ColumnLayout {
        visible: otpConfigurationPanel.credentialTypeChallengeResponse
        Layout.rightMargin: -12

        SettingsPanelChalResp{id: otpChallengeResponse}
    }

    ColumnLayout {
        visible: otpConfigurationPanel.credentialTypeStaticPassword
        Layout.rightMargin: -12

        SettingsPanelOtpStatic{id: otpStaticPassword}
    }

    ColumnLayout {
        visible: otpConfigurationPanel.credentialTypeOATHHOTP

        SettingsPanelOathHotp{ id: oathHotp}
    }

    RowLayout {
        Layout.topMargin: 16
        Layout.alignment: Qt.AlignRight | Qt.AlignTop

        StyledButton {
            Layout.alignment: Qt.AlignRight | Qt.AlignTop
            enabled: slotConfigured
            text: qsTr("Delete")
            onClicked: {
                confirmDelete()
            }
        }
        StyledButton {
            Layout.alignment: Qt.AlignRight | Qt.AlignTop
            text: qsTr("Apply")
            enabled: {
                if (otpConfigurationPanel.credentialTypeStaticPassword) {
                    otpStaticPassword.changed
                }else if (otpConfigurationPanel.credentialTypeYubicoOTP) {
                    yubicoOTP.changed
                }else if (otpConfigurationPanel.credentialTypeChallengeResponse) {
                    otpChallengeResponse.changed
                }else if (otpConfigurationPanel.credentialTypeOATHHOTP) {
                    oathHotp.changed
                }else {
                    false
                }
            }
            onClicked: {
                if (otpConfigurationPanel.credentialTypeStaticPassword) {
                    otpStaticPassword.programStaticPassword(slot+1)
                    updateCounter++
                }
                if (otpConfigurationPanel.credentialTypeYubicoOTP) {
                    yubicoOTP.programYubiOtp(slot+1)
                    updateCounter++
                }
                if (otpConfigurationPanel.credentialTypeChallengeResponse) {
                    otpChallengeResponse.programChallengeResponse(slot+1)
                    updateCounter++
                }
                if (otpConfigurationPanel.credentialTypeOATHHOTP) {
                    oathHotp.programOathHotp(slot+1)
                    updateCounter++
                }
            }
        }
    }
}

