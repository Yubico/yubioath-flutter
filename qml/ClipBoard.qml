import QtQuick 2.5

TextEdit {
    visible: false
    function push(value) {
        text = value
        selectAll()
        copy()
    }
}
