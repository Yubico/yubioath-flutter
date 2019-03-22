import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2

Pane {
    id: pane
    objectName: 'newCredentialView'

    property string title: "New credential"

    function addCredential() {
        yubiKey.addCredential(nameLbl.text, secretKeyLbl.text, issuerLbl.text,
                              oathTypeComboBox.currentText,
                              algoComboBox.currentText,
                              digitsComboBox.currentText, periodSpinBox.value,
                              requireTouchCheckBox.checked, function (resp) {
                                  if (resp.success) {
                                      // TODO: This should be a callback or similar,
                                      // so that the view changes after the entries
                                      // are refreshed. Should also show a success message.
                                      yubiKeyPoller.calculateAll()
                                      app.goToCredentials()
                                  } else {
                                      console.log(resp.error_id)
                                  }
                              })
    }

    ColumnLayout {
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        TextField {
            id: issuerLbl
            placeholderText: "Issuer"
            Layout.fillWidth: true
        }
        TextField {
            id: nameLbl
            placeholderText: "Account name"
            Layout.fillWidth: true
        }
        TextField {
            id: secretKeyLbl
            placeholderText: "Secret key"
            Layout.fillWidth: true
        }

        CheckBox {
            id: requireTouchCheckBox
            text: "Require touch"
        }
        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "Type"
                Layout.fillWidth: true
            }
            ComboBox {
                id: oathTypeComboBox
                model: ["TOTP", "HOTP"]
            }
        }
        RowLayout {
            Label {
                text: "Digits"
                Layout.fillWidth: true
            }
            ComboBox {
                id: digitsComboBox
                model: ["6", "7", "8"]
            }
        }
        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "Algorithm"
                Layout.fillWidth: true
            }
            ComboBox {
                id: algoComboBox
                model: ["SHA1", "SHA256", "SHA512"]
            }
        }
        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "Period"
                Layout.fillWidth: true
            }
            SpinBox {
                id: periodSpinBox
                value: 30
            }
        }

        Button {
            id: addBtn
            text: "Add"
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            highlighted: true
            onClicked: addCredential()
        }
    }
}
