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
    property var last_template

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
                text: progressBar.value > 0 ? qsTr("Keep touching your YubiKey until your fingerprint is captured") : qsTr("Touch your YubiKey to capture your fingerprint")
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
                visible: progressBar.value < 1
                primary: false
                onClicked: navigator.pop()
                Keys.onEnterPressed: navigator.pop()
                Keys.onReturnPressed: navigator.pop()
            }

            StyledButton {
                text: qsTr("Continue")
                visible: progressBar.value === 1
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                primary: true
                onClicked: navigator.confirmInput({
                    "promptMode": true,
                    "heading": qsTr("Add fingerprint"),
                    "text1": qsTr("Enter a name for this fingerprint"),
                    "promptText": qsTr("Name"),
                    "acceptedCb": function(resp) {
                        yubiKey.bioRename(last_template, resp, function (resp_inner) {
                            if (resp_inner.success) {
                                console.log("fingerprint renamed")
                            } else {
                                console.log("error renaming fingerprint")
                            }
                        })
                        navigator.pop()
                        navigator.snackBar(qsTr("Fingerprint added"))
                    }
                })
                Keys.onEnterPressed: click()
                Keys.onReturnPressed: click()
            }

        }
    }

    function enroll(){
        yubiKey.bioEnroll("", function (resp) {
            if (resp.success) {
                if (resp.remaining > 0) {
                    progressBar.value = progressBar.value + 0.2
                    enroll()
                } else {
                    progressBar.value = 1
                    last_template = resp.template
                }
            } else {
                if (resp.error_id > 0) {
                    enroll()
                }
                //navigator.snackBarError(qsTr("Fingerprint not added"))
            }
        })

    }
}
