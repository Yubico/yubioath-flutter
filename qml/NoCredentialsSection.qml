import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ColumnLayout {

    readonly property int dynamicWidth: 600
    readonly property int dynamicMargin: 64

    spacing: 20

    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

        StyledImage {
            source: "../images/people.svg"
            color: app.isDark() ? defaultLightForeground : defaultLightOverlay
            iconWidth: 80
            Layout.leftMargin: -3
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
            text: "This YubiKey contains no credentials, how about adding some? Click the + sign in the toolbar to get started."
            Layout.minimumWidth: 320
            Layout.maximumWidth: app.width - dynamicMargin
                                 < dynamicWidth ? app.width - dynamicMargin : dynamicWidth
            Layout.rowSpan: 1
            lineHeight: 1.1
            wrapMode: Text.WordWrap
            font.pixelSize: 12
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }
    }
}
