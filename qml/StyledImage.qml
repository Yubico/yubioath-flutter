import QtQuick 2.9
import QtQuick.Controls 2.3

Button {
    property string source
    property string color
    property int iconWidth
    property int iconHeight

    padding: 0
    icon.source: source
    icon.color: color
    icon.width: iconWidth
    icon.height: iconHeight
    flat: true
    enabled: false
}
