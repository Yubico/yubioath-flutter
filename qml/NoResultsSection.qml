import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

ColumnLayout {

    readonly property int dynamicWidth: 380
    readonly property int dynamicMargin: 64

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter

    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        Layout.topMargin: -80

        StyledImage {
            source: "../images/search.svg"
            color: app.isDark() ? defaultLightForeground : defaultLightOverlay
            iconWidth: 80
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }

        Label {
            text: qsTr("No credentials found")
            Layout.rowSpan: 1
            wrapMode: Text.WordWrap
            font.pixelSize: 16
            font.weight: Font.Normal
            lineHeight: 1.5
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            color: formText
        }
        Label {
            text: qsTr("No credentials matching your search criteria. Check your spelling and try again.")
            horizontalAlignment: Qt.AlignHCenter
            Layout.minimumWidth: 320
            Layout.maximumWidth: app.width - dynamicMargin
                                 < dynamicWidth ? app.width - dynamicMargin : dynamicWidth
            Layout.rowSpan: 1
            lineHeight: 1.1
            wrapMode: Text.WordWrap
            font.pixelSize: 13
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            color: formLabel
        }
    }
}
