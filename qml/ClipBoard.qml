import QtQuick 2.5

TextEdit {
    visible: false
    function setClipboard(value) {
        text = value
        selectAll()
        copy()
    }
}
