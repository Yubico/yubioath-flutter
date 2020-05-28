import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2

InlinePopup {
    closePolicy: Popup.NoAutoClose
    Heading2 {
        width: parent.width
        text: qsTr("Remove and re-insert your YubiKey!")
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }
}
