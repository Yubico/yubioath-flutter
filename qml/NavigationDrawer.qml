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

    function toggle() {
        drawer.visible =! drawer.visible
    }

    function getStartingIndex() {
        if (navigator.isInAuthenticator() || navigator.isInNewOathCredential() || navigator.isInEnterPassword()) {
            return 0
        } else if (navigator.isInYubiKeyView()) {
            return 1
        } else if (navigator.isInSettings()) {
            return 2
        } else if (navigator.isInAbout()) {
            return 3
        } else {
            return 0
        }
    }

    function selectItemByIndex() {
        switch(hoverIndex) {
        case 0:
            navigator.goToAuthenticator()
            break
        case 1:
            navigator.goToYubiKey()
            break
        case 2:
            navigator.goToSettings()
            break
        case 3:
            navigator.goToAbout()
            break
        }
        drawer.close()
    }

    property string deviceName: !!yubiKey.currentDevice ? yubiKey.currentDevice.name : "Insert your YubiKey"
    property string deviceSerial: !!yubiKey.currentDevice && !!yubiKey.currentDevice.serial ? yubiKey.currentDevice.serial : ""
    property string deviceVersion: !!yubiKey.currentDevice && !!yubiKey.currentDevice.version ? yubiKey.currentDevice.version : ""
    property string deviceImage: !!yubiKey.currentDevice ? yubiKey.getCurrentDeviceImage() : "../images/ykfamily.svg"

    property int hoverIndex: 0
    property var currentItem: !!navigator.currentItem ? navigator.currentItem.objectName : null

    onOpened: hoverIndex = getStartingIndex()
    onCurrentItemChanged: hoverIndex = getStartingIndex()

    background: Rectangle {
        anchors.fill: parent
        color: defaultElevated
    }

    Shortcut {
        id: shortcutMoveUp
        sequence: "Up"
        onActivated: hoverIndex--
        enabled: drawer.visible && hoverIndex > 0
    }

    Shortcut {
        id: shortcutMoveBackTab
        sequence: "Shift+Tab"
        onActivated: hoverIndex--
        enabled: drawer.visible && hoverIndex > 0
    }

    Shortcut {
        id: shortcutMoveDown
        sequence: "Down"
        onActivated: hoverIndex++
        enabled: drawer.visible  && hoverIndex < 3
    }

    Shortcut {
        id: shortcutMoveTab
        sequence: "Tab"
        onActivated: hoverIndex++
        enabled: drawer.visible  && hoverIndex < 3
    }

    Shortcut {
        id: shortcutReturn
        sequence: "Return"
        onActivated: selectItemByIndex()
        enabled: drawer.visible
    }

    Shortcut {
        id: shortcutLeft
        sequence: "Left"
        onActivated: drawer.close()
        enabled: drawer.visible
    }

    Shortcut {
        id: shortcutRight
        sequence: "Right"
        onActivated: drawer.close()
        enabled: drawer.visible
    }

    Flickable {
        clip: true
        anchors.fill: parent
        contentWidth: drawer.width
        contentHeight: content.implicitHeight + 32
        ScrollBar.vertical: ScrollBar {
            width: 8
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            hoverEnabled: true
            z: 2
        }
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: content

            Rectangle {
                id: ykCircle
                width: 60
                height: 60
                color: formHighlightItem
                radius: width * 0.5
                Layout.topMargin: 32
                Layout.leftMargin: 16
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
                Layout.topMargin: 32
                Layout.leftMargin: 16
                iconHeight: 60
                visible: !ykCircle.visible
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
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
                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
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
                isActive: navigator.isInAuthenticator() || navigator.isInNewOathCredential() || navigator.isInEnterPassword()
                isHovered: hoverIndex === 0
            }
            NavigationItem {
                icon: "../images/yubikey-vertical.svg"
                text: "YubiKey"
                onActivated: navigator.goToYubiKey()
                isActive: navigator.isInYubiKeyView()
                isHovered: hoverIndex === 1
            }
            NavigationItem {
                icon: "../images/cogwheel.svg"
                text: "Settings"
                onActivated: navigator.goToSettings()
                isActive: navigator.isInSettings()
                isHovered: hoverIndex === 2
            }
            NavigationItem {
                icon: "../images/help.svg"
                text: "About"
                onActivated: navigator.goToAbout()
                isActive: navigator.isInAbout()
                isHovered: hoverIndex === 3
            }
        }
    }
}
