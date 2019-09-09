import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Pane {
    id: pane

    readonly property int dynamicWidth: 600
    readonly property int dynamicMargin: 32

    spacing: 8
    padding: 32

    objectName: 'loadingView'
    contentWidth: app.width

    BusyIndicator {
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
