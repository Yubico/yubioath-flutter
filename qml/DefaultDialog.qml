import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Window 2.2

ApplicationWindow {

    SystemPalette {
        id: palette
    }

    flags: Qt.Dialog | Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowCloseButtonHint | Qt.MSWindowsFixedSizeDialogHint
    modality: Qt.ApplicationModal
    color: palette.window

    default property alias content: inner_content.data
    signal accepted
    signal rejected
    property int margins: 12

    ColumnLayout {
        id: outer_content
        anchors.fill: parent
        anchors.margins: margins

        ColumnLayout {
            id: inner_content

            // Workaround for https://bugreports.qt.io/browse/QTBUG-51927
            // Fixed in Qt 5.7.1 and 5.6.2
            Component.onDestruction: {
                while (children.length > 0)
                    children[children.length - 1].parent = destruction_parent
            }
        }

        Item {
            id: destruction_parent
        }
    }

    function resize() {
        setWidth(width)
    }
}
