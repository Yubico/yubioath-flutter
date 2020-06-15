import QtQuick 2.5

TextEdit {

    function push(value) {
        text = value;
        selectAll();
        copy();
    }

    visible: false
}
