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
    modal: true
    interactive: true
    y: toolBar.height
    height: app.height-toolBar.height

    Overlay.modal: Rectangle {
        color: "#33000000"
    }

    property string deviceName: !!yubiKey.currentDevice ? yubiKey.currentDevice.name : "Insert YubiKey"
    property string deviceSerial: !!yubiKey.currentDevice && !!yubiKey.currentDevice.serial ? yubiKey.currentDevice.serial : ""
    property string deviceVersion: !!yubiKey.currentDevice && !!yubiKey.currentDevice.version ? yubiKey.currentDevice.version : ""
    property string deviceImage: !!yubiKey.currentDevice ? yubiKey.getCurrentDeviceImage() : "../images/ykfamily.svg"

    background: Rectangle {
        anchors.fill: parent
        color: defaultElevated
    }

    function toggle() {
        drawer.visible =! drawer.visible
    }

    ColumnLayout {
        Rectangle {
            id: ykCircle
            width: 60
            height: 60
            color: formHighlightItem
            radius: width * 0.5
            Layout.topMargin: 16
            Layout.leftMargin: 16
            Layout.bottomMargin: 8
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            visible: !!yubiKey.currentDevice
            Image {
                id: ykImage
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                sourceSize.width: 40
                source: deviceImage
                fillMode: Image.PreserveAspectFit
            }
        }
        StyledImage {
            id: yubikeys
            source: "../images/ykfamily.svg"
            color: defaultImageOverlay
            Layout.topMargin: 16
            Layout.leftMargin: 16
            iconHeight: 70
            visible: !ykCircle.visible
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        }

        Label {
            text: deviceName
            font.pixelSize: 16
            font.weight: Font.Normal
            Layout.leftMargin: 16
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            color: primaryColor
            opacity: highEmphasis
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        }

        Canvas {
            id: canvas
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
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
            text: "Authenticator"
            onActivated: navigator.goToAuthenticator()
            isActive: isCurrentObjectName(['authenticatorView', 'enterPasswordView', 'newCredentialView'])
        }
        NavigationItem {
            icon: "../images/yubikey-vertical.svg"
            text: "Configure YubiKey"
            onActivated: navigator.goToYubiKey()
            isActive: isCurrentObjectName('yubiKeyView')
        }
        NavigationItem {
            icon: "../images/cogwheel.svg"
            text: "Settings"
            onActivated: navigator.goToSettings()
            isActive: isCurrentObjectName('settingsView')
        }
        NavigationItem {
            icon: "../images/help.svg"
            text: "About"
            onActivated: navigator.goToAbout()
            isActive: isCurrentObjectName('aboutView')
        }
    }
}
