import QtQuick 2.5

Item {

    focus: true

    property var credRepeater
    property int nCreds: credRepeater.model.length
    property bool nothingSelected: credRepeater.selectedIndex === null
    property var firstCred: credRepeater.model[0]
    property var lastCred: credRepeater.model[nCreds - 1]
    property bool lastCredSelected: credRepeater.selectedIndex === nCreds - 1
    property bool firstCredSeleced: credRepeater.selectedIndex === 0

    Keys.onDownPressed: {
        if (nothingSelected) {
            credRepeater.selected = firstCred
            credRepeater.selectedIndex = 0
        } else if (!lastCredSelected) {
            credRepeater.selected = credRepeater.model[credRepeater.selectedIndex + 1]
            credRepeater.selectedIndex = credRepeater.selectedIndex + 1
        }
    }

    Keys.onUpPressed: {
        if (nothingSelected) {
            credRepeater.selected = lastCred
            credRepeater.selectedIndex = nCreds - 1
        } else if (!firstCredSeleced) {
            credRepeater.selected = credRepeater.model[credRepeater.selectedIndex - 1]
            credRepeater.selectedIndex = credRepeater.selectedIndex - 1
        }
    }

}
