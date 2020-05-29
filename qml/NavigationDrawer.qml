import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import Qt.labs.settings 1.0
import QtQuick.Window 2.2
import QtQml 2.12
import QtGraphicalEffects 1.12

Drawer {
    id: drawer
    width: 210
    height: app.height
    Overlay.modal: Rectangle {
        color: "#66000000"
    }

    property string deviceName: !!yubiKey.currentDevice ? yubiKey.currentDevice.name : "Insert your YubiKey"
    property string deviceSerial: !!yubiKey.currentDevice && !!yubiKey.currentDevice.serial ? yubiKey.currentDevice.serial : ""
    property string deviceVersion: !!yubiKey.currentDevice && !!yubiKey.currentDevice.version ? yubiKey.currentDevice.version : ""
    property string deviceImage: !!yubiKey.currentDevice ? yubiKey.getCurrentDeviceImage() : "../images/ykfamily.svg"

    background: Rectangle {
        anchors.fill: parent
        color: defaultBackground
    }

    ColumnLayout {
        Rectangle {
            id: ykCircle
            width: 70
            height: 70
            color: formHighlightItem
            radius: width * 0.5
            Layout.topMargin: 32
            Layout.bottomMargin: 16
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            visible: !!yubiKey.currentDevice
            Image {
                id: ykImage
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                sourceSize.width: 50
                source: deviceImage
                fillMode: Image.PreserveAspectFit
            }
        }
        StyledImage {
            id: yubikeys
            source: "../images/ykfamily.svg"
            color: defaultImageOverlay
            Layout.topMargin: 32
            iconHeight: 70
            Layout.bottomMargin: 16
            visible: !ykCircle.visible
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }

        Label {
            text: deviceName
            font.pixelSize: 16
            font.weight: Font.Normal
            lineHeight: 1.8
            color: primaryColor
            opacity: highEmphasis
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }

        Canvas {
            id: canvas
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            Layout.fillWidth: true
            Layout.fillHeight: true
            width: 210
            height: 24
            onPaint: {
                var context = getContext("2d");
                context.beginPath();
                context.lineWidth = 1;
                context.moveTo(0, height / 2);
                context.strokeStyle = formHighlightItem
                context.lineTo(width, height / 2);
                context.stroke();
            }
        }

        NavigationItem {
            icon: "../images/people.svg"
            text: "Accounts"
            onActivated: navigator.home()
            visible: !!yubiKey.currentDevice
            isActive: !!(navigator.currentItem)
                      && (navigator.currentItem.objectName === 'credentialsView'
                      || navigator.currentItem.objectName === 'enterPasswordView')
        }
        NavigationItem {
            icon: "../images/cogwheel.svg"
            text: "Settings"
            onActivated: navigator.goToSettings()
            isActive: !!(navigator.currentItem)
                      && (navigator.currentItem.objectName === 'settingsView')
        }
        NavigationItem {
            icon: "../images/info.svg"
            text: "About"
            onActivated: navigator.goToAbout()
            isActive: !!(navigator.currentItem)
                      && (navigator.currentItem.objectName === 'aboutView')
        }
    }
}
