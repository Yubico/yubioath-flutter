import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Pane {
    objectName: 'enterPasswordView'

    property string title: "Unlock YubiKey"

    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        ColumnLayout {
            spacing: 20
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Image {
                    id: lock
                    sourceSize.height: 60
                    sourceSize.width: 100
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    fillMode: Image.PreserveAspectFit
                    source: "../images/lock.svg"
                    ColorOverlay {
                        source: lock
                        color: app.isDark() ? app.defaultDarkOverlay : app.defaultLightOverlay
                        anchors.fill: lock
                    }
                }
                Label {
                    text: "The YubiKey is password protected"
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                }
            }
            ColumnLayout {
                Layout.alignment: Qt.AlignLeft | Qt.AlignBottom
                TextField {
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    Layout.fillWidth: true
                    placeholderText: qsTr("Password")
                    background.width: width
                }
                RowLayout {
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    Button {
                        highlighted: false
                        text: "Cancel"
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        onClicked: app.goToNoYubiKeyView()
                    }
                    Button {
                        highlighted: true
                        text: "OK"
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        onClicked: app.goToCredentials()
                    }
                }
            }
        }
    }
}
