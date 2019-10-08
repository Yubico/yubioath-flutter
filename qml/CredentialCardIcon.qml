import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import "utils.js" as Utils

Rectangle {

    property string letter: getIconLetter()
    property int size: 40
    property var shade: isDark() ? Material.Shade200 : Material.Shade800
    width: size
    height: size
    radius: width * 0.5
    color: getIconColor()

    /*
      For Light Mode we are intentionally violating accessibility guidelines for the following colors:
      LightGreen, Lime, Yellow, Amber, Orange
    */
    readonly property var iconColors: [
        Material.color(Material.Red, shade),
        Material.color(Material.Pink, shade),
        Material.color(Material.Purple, shade),
        Material.color(Material.DeepPurple, shade),
        Material.color(Material.Indigo, shade),
        Material.color(Material.Blue, shade),
        Material.color(Material.LightBlue, shade),
        Material.color(Material.Cyan, shade),
        Material.color(Material.Teal, shade),
        Material.color(Material.Green, shade),
        Material.color(Material.LightGreen, shade),
        Material.color(Material.Lime, shade),
        Material.color(Material.Yellow, shade),
        Material.color(Material.Amber, shade),
        Material.color(Material.Orange, shade),
        Material.color(Material.DeepOrange, shade),
        Material.color(Material.Brown, shade),
        Material.color(Material.Grey, shade),
        Material.color(Material.BlueGrey, shade),
    ]

    /*
       This is a copy of the icon color picker algorithm found in the current Android version of YA.
       See: https://github.com/Yubico/yubioath-android/blob/master/app/src/main/kotlin/com/yubico/yubioath/ui/main/IconManager.kt#L67
    */
    function getIconColor() {
        let iconKey = credential.issuer ? credential.issuer : ":" + credential.name
        let hashCode = Utils.hashCode(iconKey)
        return iconColors[Math.abs(hashCode) % iconColors.length]
    }

    function getIconLetter() {
        return credential.issuer ? credential.issuer.charAt(
                                       0) : credential.name.charAt(0)
    }

    Label {
        text: letter.toUpperCase()
        font.pixelSize: 24
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        color: credentialCardNormal
    }
}
