import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import "utils.js" as Utils

Rectangle {

    property string letter: getIconLetter()
    property int size: 40
    property var materialShade: isDark() ? Material.Shade300 : Material.Shade300
    width: size
    height: size
    radius: width * 0.5
    color: getIconColor()

    readonly property var iconColors: [
        Material.color(Material.Red, materialShade),
        Material.color(Material.Pink, materialShade),
        Material.color(Material.Purple, materialShade),
        Material.color(Material.DeepPurple, materialShade),
        Material.color(Material.Indigo, materialShade),
        Material.color(Material.Blue, materialShade),
        Material.color(Material.LightBlue, materialShade),
        Material.color(Material.Cyan, materialShade),
        Material.color(Material.Teal, materialShade),
        Material.color(Material.Green, materialShade),
        Material.color(Material.LightGreen, materialShade),
        Material.color(Material.Lime, materialShade),
        Material.color(Material.Yellow, materialShade),
        Material.color(Material.Amber, materialShade),
        Material.color(Material.Orange, materialShade),
        Material.color(Material.DeepOrange, materialShade),
        Material.color(Material.Brown, materialShade),
        Material.color(Material.BlueGrey, materialShade),
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
