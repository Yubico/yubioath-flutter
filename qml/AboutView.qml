import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls.Material 2.2
import QtGraphicalEffects 1.0

Flickable {
    id: panel
    objectName: 'aboutView'
    contentWidth: app.width
    contentHeight: content.visible ? content.implicitHeight + 32 : app.height - toolBar.height
    leftMargin: 0
    rightMargin: 0

    readonly property int dynamicWidth: 648
    readonly property int dynamicMargin: 32

    ScrollBar.vertical: ScrollBar {
        width: 8
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        hoverEnabled: true
        z: 2
    }
    boundsBehavior: Flickable.StopAtBounds

    Accessible.ignored: true

    property string title: ""

    ColumnLayout {
        id: content
        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        width: parent.width
        spacing: 0

        ColumnLayout {
            spacing: 0
            width: parent.width
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop

            RowLayout {
                Layout.leftMargin: 16
                Layout.topMargin: 32

                Image {
                    source: "../images/logo-small.png"
                    sourceSize.width: 40
                    sourceSize.height: 40
                    fillMode: Image.PreserveAspectFit
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                }

                Label {
                    text: qsTr("Yubico Authenticator")
                    font.pixelSize: 17
                    color: primaryColor
                    opacity: highEmphasis
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.leftMargin: 8
                }
            }

            StyledExpansionContainer {
                Layout.topMargin: 24

                StyledExpansionPanel {
                    label: qsTr("Get help with Yubico Authenticator")
                    isEnabled: false
                    toolButtonIcon: "../images/launch.svg"
                    toolButtonToolTip: qsTr("Launch Yubico Authenticator website")
                    toolButton.onClicked: Qt.openUrlExternally("https://support.yubico.com/support/home");
                }

                StyledExpansionPanel {
                    label: qsTr("Display keyboard shortcuts")

                    ColumnLayout {
                        Label {
                            text: "Global"
                            color: primaryColor
                            opacity: lowEmphasis
                            font.pixelSize: 12
                        }
                        Repeater {
                            model: [shortcutGoToAuthenticator, shortcutGoToYubiKey, shortcutGoToSettings, shortcutGoToAbout, shortcutFind, shortcutFullScreen, shortcutClose, shortcutQuit]

                            RowLayout {
                                Label {
                                    text: modelData.nativeText
                                    opacity: lowEmphasis
                                    Layout.leftMargin: 16
                                    Layout.minimumWidth: 60
                                }
                                Label {
                                    text: modelData.description
                                    opacity: lowEmphasis
                                }
                            }
                        }
                        Label {
                            text: "Authenticator"
                            color: primaryColor
                            opacity: lowEmphasis
                            font.pixelSize: 12
                            Layout.topMargin: 16
                        }
                        Repeater {
                            model: [shortcutAddAccount, shortcutCopy, shortcutDelete, shortcutToggleFavorite]

                            RowLayout {
                                Label {
                                    text: modelData.nativeText
                                    opacity: lowEmphasis
                                    Layout.leftMargin: 16
                                    Layout.minimumWidth: 60
                                }
                                Label {
                                    text: modelData.description
                                    opacity: lowEmphasis
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.leftMargin: 16
                Layout.topMargin: 24

                Label {
                    text: qsTr("Yubico Authenticator (v%1)").arg(appVersion)
                    font.pixelSize: 13
                    color: primaryColor
                    opacity: lowEmphasis
                }
                Label {
                    text: qsTr("Copyright © %1 Yubico. All rights reserved.").arg(Qt.formatDateTime(new Date(),"yyyy"))
                    font.pixelSize: 13
                    color: primaryColor
                    opacity: lowEmphasis
                }
                Text {
                    text: qsTr("<a href='https://www.yubico.com/support/terms-conditions/yubico-license-agreement/'>Terms of use</a>&nbsp;&nbsp;<a href='https://www.yubico.com/support/terms-conditions/privacy-notice/'>Privacy policy</a>")
                    font.pixelSize: 13
                    Layout.topMargin: 8
                    linkColor: yubicoGreen
                    onLinkActivated: Qt.openUrlExternally(link)
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }
                }
            }
        }
    }
}
