import QtQuick 2.9
import QtQuick.Controls 2.2

BusyIndicator {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    visible: running
    running: false
}
