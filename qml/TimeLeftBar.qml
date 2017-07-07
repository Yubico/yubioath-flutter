import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Controls.Styles 1.4

ProgressBar {
    Layout.alignment: Qt.AlignLeft | Qt.AlignTop
    Layout.maximumHeight: 10
    Layout.minimumHeight: 10
    Layout.minimumWidth: 300
    Layout.fillWidth: true
    maximumValue: 30
    minimumValue: 0
}
