import QtQuick 2.5

Item {

    focus: true

    property var credRepeater
    property int nCreds: credRepeater.model.length
    property bool nothingSelected: selectedIndex === null
    property var firstCred: credRepeater.model[0]
    property var lastCred: credRepeater.model[nCreds - 1]
    property bool lastCredSelected: selectedIndex === nCreds - 1
    property bool firstCredSeleced: selectedIndex === 0

    signal goDown()
    signal goUp()

    Keys.onDownPressed: goDown()
    Keys.onUpPressed: goUp()

    onGoDown: {
        flickable.flick(0, -300)
        if (nothingSelected) {
            selected = firstCred
            selectedIndex = 0
        } else if (!lastCredSelected) {
            selected = credRepeater.model[selectedIndex + 1]
            selectedIndex = selectedIndex + 1
        }

    }

    onGoUp: {
        flickable.flick(0, 300)
        if (nothingSelected) {
            selected = lastCred
            selectedIndex = nCreds - 1
        } else if (!firstCredSeleced) {
            selected = credRepeater.model[selectedIndex - 1]
            selectedIndex = selectedIndex - 1
        }
    }

    Keys.onReturnPressed: generateOrCopy()
    Keys.onEnterPressed: generateOrCopy()
    Keys.onEscapePressed: deselectCredential()
}
