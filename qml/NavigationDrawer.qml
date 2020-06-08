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
    modal: sticky
    interactive: sticky
    height: app.height

    property bool sticky: app.width < 510

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
            Layout.bottomMargin: 8
            iconHeight: 70
            visible: !ykCircle.visible
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        }

        Label {
            text: deviceName
            font.pixelSize: 16
            font.weight: Font.Normal
            Layout.leftMargin: 16
            color: primaryColor
            opacity: highEmphasis
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
        }

        Label {
            text: "%1 account%2".arg(!entries ? "0" : entries.count).arg(entries.count !== 1 ? "s" : "")
            font.pixelSize: 12
            font.weight: Font.Normal
            Layout.leftMargin: 16
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
            text: "Authenticator app"
            onActivated: navigator.home()
            visible: !!yubiKey.currentDevice && yubiKey.currentDevice
            isActive: !!(navigator.currentItem)
                      && (navigator.currentItem.objectName === 'credentialsView'
                      || navigator.currentItem.objectName === 'enterPasswordView')
        }
        NavigationItem {
            icon: "../images/info.svg"
            text: "YubiKey"
            visible: !!yubiKey.currentDevice
            onActivated: navigator.goToAbout()
            isActive: !!(navigator.currentItem)
                      && (navigator.currentItem.objectName === 'aboutView')
        }
        NavigationItem {
            icon: "../images/cogwheel.svg"
            text: "Settings"
            onActivated: navigator.goToSettings()
            isActive: !!(navigator.currentItem)
                      && (navigator.currentItem.objectName === 'settingsView')
        }
        NavigationItem {
            icon: "../images/help.svg"
            text: "About"
            onActivated: navigator.confirm({
                       "message": qsTr("Yubico Authenticator v%1").arg(appVersion),
                       "description": qsTr("Copyright © " + Qt.formatDateTime(new Date(),"yyyy") + ", Yubico AB." +
                                           qsTr("\n\nAll rights reserved.")),
                       "warning": false,
                       "buttons": false,
                       "noicon": true
                   })
        }
    }
}
