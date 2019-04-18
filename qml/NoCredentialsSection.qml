import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ColumnLayout {
    spacing: 20
    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        Image {
            id: people
            sourceSize.width: 80
            Layout.alignment: parent.left | Qt.AlignVCenter
            Layout.topMargin: 10
            Layout.leftMargin: -4
            Layout.bottomMargin: 0
            fillMode: Image.PreserveAspectFit
            source: "../images/people.svg"

            ColorOverlay {
                source: people
                color: app.isDark(
                           ) ? defaultLightForeground : defaultLightOverlay
                anchors.fill: people
                antialiasing: true
            }
        }

        Button {
            icon.source: "../images/people.svg"
            icon.color: "red"
            icon.width: 80
            icon.height: 80
            flat: true
            enabled: false
        }

        Label {
            text: "No credentials"
            Layout.rowSpan: 1
            wrapMode: Text.WordWrap
            font.pixelSize: 12
            font.bold: true
            lineHeight: 1.5
            Layout.alignment: Qt.AlignHLeft | Qt.AlignVCenter
        }
        Label {
            text: "This YubiKey contains no credentials, how about adding some? For more information how it works please refer to yubico.com/authenticator."
            Layout.minimumWidth: 320
            Layout.maximumWidth: app.width - 100 < 600 ? app.width - 100 : 600
            Layout.rowSpan: 1
            lineHeight: 1.1
            wrapMode: Text.WordWrap
            font.pixelSize: 12
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }
    }
}
