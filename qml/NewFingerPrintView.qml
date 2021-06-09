import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {

    id: settingsPanel
    objectName: 'newFingerPrintViewFlickable'
    contentWidth: app.width
    contentHeight: expandedHeight
    StackView.onActivating: enroll()

    property var expandedHeight: content.implicitHeight + dynamicMargin

    onExpandedHeightChanged: {
        if (expandedHeight > app.height - toolBar.height) {
             scrollBar.active = true
         }
    }

    ScrollBar.vertical: ScrollBar {
        id: scrollBar
        width: 8
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        hoverEnabled: true
        z: 2
    }
    boundsBehavior: Flickable.StopAtBounds

    property string searchFieldPlaceholder: ""

    ColumnLayout {
        width: settingsPanel.contentWidth
        id: content
        spacing: 0

        ColumnLayout {
            width: settingsPanel.contentWidth - 32
            Layout.leftMargin: 16
            Layout.rightMargin: 16

            Label {
                text: "Add fingerprint"
                font.pixelSize: 16
                font.weight: Font.Normal
                color: yubicoGreen
                opacity: fullEmphasis
                Layout.topMargin: 24
                Layout.bottomMargin: 24
                Layout.fillWidth: true
            }

            Label {
                text: qsTr("Keep touching your YubiKey until your fingerprint is captured")
                color: primaryColor
                opacity: lowEmphasis
                font.pixelSize: 13
                lineHeight: 1.2
                textFormat: TextEdit.PlainText
                wrapMode: Text.WordWrap
                Layout.maximumWidth: parent.width
                Layout.bottomMargin: 32
            }

            StyledImage {
                id: fingerprintIcon
                source: "../images/fingerprint.svg"
                color: primaryColor
                opacity: lowEmphasis
                iconWidth: 150
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                bottomPadding: 32
            }

            ProgressBar {
                id: progressBar
                value: 0
                Layout.fillWidth: true
                Layout.bottomMargin: 32
            }

            StyledButton {
                text: qsTr("Cancel")
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                primary: false
                onClicked: navigator.pop()
                Keys.onEnterPressed: navigator.pop()
                Keys.onReturnPressed: navigator.pop()
            }

        }
    }

    function enroll(){
        yubiKey.bioEnroll("test3", function (resp) {
            if (resp.success) {
                if (resp.remaining > 0) {
                    console.log("success")
                    progressBar.value = progressBar.value + 0.2
                    enroll()
                } else {

                    navigator.goToFingerPrintsView()
                    navigator.snackBar(qsTr("Fingerprint added"))
                }
            } else {
                if (resp.error_id > 0) {
                    console.log("fail")
                    enroll()
                }
                //navigator.snackBarError(qsTr("Fingerprint not added"))
            }
        })

    }
}
