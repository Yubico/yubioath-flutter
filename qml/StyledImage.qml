import QtQuick 2.9
import QtQuick.Controls 2.3

Button {
    property string source
    property string color
    property int iconWidth
    property int iconHeight

    width: iconWidth
    height: iconHeight
    spacing: 0
    rightPadding: 0
    leftPadding: 0
    padding: 0
    icon.source: source
    icon.color: color
    icon.width: iconWidth
    icon.height: iconHeight
    flat: true
    enabled: false
}
