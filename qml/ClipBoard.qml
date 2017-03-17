import QtQuick 2.5

TextEdit {
    id: clipboard
    visible: false
    function setClipboard(value) {
        text = value
        selectAll()
        copy()
    }
}
