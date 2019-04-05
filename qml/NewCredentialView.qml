import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Pane {
    id: pane
    objectName: 'newCredentialView'
    topPadding: 0

    property string title: "New credential"

    property var credential
    property bool manualEntry
    property bool showAdvanced: false

    anchors.fill: parent

    function addCredential() {
        yubiKey.addCredential(nameLbl.text, secretKeyLbl.text, issuerLbl.text,
                              oathTypeComboBox.currentText,
                              algoComboBox.currentText,
                              digitsComboBox.currentText, periodLbl.text,
                              requireTouchCheckBox.checked, function (resp) {
                                  if (resp.success) {
                                      // TODO: This should be a callback or similar,
                                      // so that the view changes after the entries
                                      // are refreshed.
                                      yubiKeyPoller.calculateAll()
                                      navigator.goToCredentials()
                                      navigator.snackBar("Credential added")
                                  } else {
                                      navigator.snackBarError(
                                                  navigator.getErrorMessage(
                                                      resp.error_id))
                                      console.log("addCredential failed:",
                                                  resp.error_id)
                                  }
                              })
    }

    Pane {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.topMargin: 0
        anchors.bottomMargin: -10
        anchors.horizontalCenter: parent.horizontalCenter
        padding: 20
        width: 360
        background: Rectangle {
            color: isDark() ? defaultDarkLighter : defaultLightDarker
        }

        ColumnLayout {
            anchors.top: parent.top
            anchors.topMargin: 0
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.right: parent.right
            anchors.rightMargin: 0
            spacing: 0

            TextField {
                id: issuerLbl
                placeholderText: "Issuer"
                Layout.fillWidth: true
                selectByMouse: true
                text: credential && credential.issuer ? credential.issuer : ""
                selectedTextColor: isDark(
                                       ) ? defaultLightForeground : defaultDarkForeground
                Material.accent: isDark(
                                     ) ? defaultDarkForeground : defaultLightForeground
            }
            TextField {
                id: nameLbl
                placeholderText: "Account name"
                Layout.fillWidth: true
                selectByMouse: true
                text: credential && credential.name ? credential.name : ""
                selectedTextColor: isDark(
                                       ) ? defaultLightForeground : defaultDarkForeground
                Material.accent: isDark(
                                     ) ? defaultDarkForeground : defaultLightForeground
            }
            TextField {
                id: secretKeyLbl
                placeholderText: "Secret key"
                Layout.fillWidth: true
                selectByMouse: true
                text: credential && credential.secret ? credential.secret : ""
                visible: manualEntry
                selectedTextColor: isDark(
                                       ) ? defaultLightForeground : defaultDarkForeground
                Material.accent: isDark(
                                     ) ? defaultDarkForeground : defaultLightForeground
                validator: RegExpValidator {
                    regExp: /[2-7a-zA-Z ]+=*/
                }
            }

            RowLayout {
                Label {
                    text: "Require touch"
                    Layout.fillWidth: true
                }
                CheckBox {
                    id: requireTouchCheckBox
                    //text: "Require touch"
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: "Type"
                    Layout.fillWidth: true
                }
                StyledComboBox {
                    id: oathTypeComboBox
                    model: ["TOTP", "HOTP"]
                }
                visible: manualEntry && showAdvanced
            }
            RowLayout {
                Label {
                    text: "Digits"
                    Layout.fillWidth: true
                }
                StyledComboBox {
                    id: digitsComboBox
                    model: ["6", "7", "8"]
                }
                visible: manualEntry && showAdvanced
            }
            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: "Algorithm"
                    Layout.fillWidth: true
                }
                StyledComboBox {
                    id: algoComboBox
                    model: ["SHA1", "SHA256", "SHA512"]
                }
                visible: manualEntry && showAdvanced
            }

            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: "Period"
                    Layout.fillWidth: true
                }
                TextField {
                    id: periodLbl
                    placeholderText: "Period"
                    Layout.fillWidth: false
                    text: "30"
                    implicitWidth: 50
                    horizontalAlignment: Text.AlignHCenter
                    validator: IntValidator {
                        bottom: 15
                        top: 60
                    }
                    selectByMouse: true
                }
                visible: manualEntry && showAdvanced
            }
            RowLayout {
                ToolButton {
                    id: showAdvancedBtn
                    onClicked: showAdvanced ? showAdvanced = false : showAdvanced = true

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: false
                    }

                    Image {
                        id: downIcon
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        Layout.maximumWidth: 150
                        fillMode: Image.PreserveAspectFit
                        source: showAdvanced ? "../images/up.svg" : "../images/down.svg"
                        ColorOverlay {
                            source: downIcon
                            color: isDark() ? yubicoWhite : yubicoGrey
                            anchors.fill: downIcon
                        }
                    }
                }

                Label {
                    text: showAdvanced ? "Show less settings" : "Show more settings"
                    elide: Label.ElideRight
                    horizontalAlignment: Qt.AlignHLeft
                    verticalAlignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                }
                visible: manualEntry
            }

            StyledButton {
                id: addBtn
                text: "Add"
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                onClicked: addCredential()
            }
        }
    }
}
