import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Pane {

    id: credentialCard

    implicitWidth: 360
    implicitHeight: 80

    Material.elevation: 0

    property var code
    property var credential

    property string issuer: credential.issuer || ''
    property string name: credential.name
    property bool touch: credential.touch
    property string oathType: credential.oath_type

    property bool continuousCalculation: oathType === "TOTP" && !touch

    background: Rectangle {
        color: if (credentialCard.GridView.isCurrentItem) {
                   return app.isDark(
                               ) ? app.defaultDarkSelection : app.defaultLightSelection
               } else {
                   return app.isDark(
                               ) ? app.defaultDarkLighter : app.defaultLightDarker
               }

        MouseArea {
            anchors.fill: parent
            onClicked: credentialCard.GridView.isCurrentItem ? credentialCard.GridView.view.currentIndex = -1 : credentialCard.GridView.view.currentIndex = index
            onDoubleClicked: {
                console.log(code.value) // TODO: copy to clipboard
            }
        }
    }

    function formattedCode(code) {
        // Add a space in the code for easier reading.
        if (code !== null) {
            switch (code.length) {
            case 6:
                // 123 123
                return code.slice(0, 3) + " " + code.slice(3)
            case 7:
                // 1234 123
                return code.slice(0, 4) + " " + code.slice(4)
            case 8:
                // 1234 1234
                return code.slice(0, 4) + " " + code.slice(4)
            default:
                return code
            }
        }
    }

    function formattedName(issuer, name) {
        if (issuer !== "") {
            return issuer + " (" + name + ")"
        } else {
            return name
        }
    }

    Item {
        anchors.fill: parent

        CredentialCardIcon {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            size: 40
            letter: issuer ? issuer.charAt(0) : name.charAt(0)
        }

        ColumnLayout {
            anchors.left: icon.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 0
            Label {
                id: codLbl
                font.pixelSize: 24
                color: !touch ? yubicoGreen : yubicoGrey
                text: code && code.value ? formattedCode(
                                               code.value) : "Requires touch"
                visible: code || touch
            }
            Label {
                id: nameLbl
                text: formattedName(issuer, name)
                Layout.maximumWidth: 265
                font.pixelSize: 12
                maximumLineCount: 3
                wrapMode: Text.Wrap
            }
        }

        CredentialCardTimer {
            code: credentialCard.code
            period: credential && credential.period ? credential.period : 0
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom
            colorCircle: Material.primary
            visible: !touch
        }

        Image {
            id: touchIcon
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: 16
            height: 16
            fillMode: Image.PreserveAspectFit
            source: "../images/touch.png"
            visible: touch
        }
    }
}
