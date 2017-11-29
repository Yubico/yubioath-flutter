import QtQuick 2.5

Item {
    property var credRepeater
    property int nCreds: credRepeater.model.length
    property bool nothingSelected: selectedKey === null
    property var firstCred: credRepeater.model[0]
    property var lastCred: credRepeater.model[nCreds - 1]
    property bool lastCredSelected: lastCred !== undefined && selectedKey === lastCred.credential.key
    property bool firstCredSeleced: firstCred !== undefined && selectedKey === firstCred.credential.key

    signal goDown()
    signal goUp()

    Keys.onDownPressed: goDown()
    Keys.onUpPressed: goUp()

    function findSelectedIndex() {
        return credRepeater.model.findIndex(function(entry) {
            return entry.credential.key === selectedKey
        }) || null
    }

    onGoDown: {
        flickable.flick(0, -300)
        if (nothingSelected) {
            selectedKey = firstCred.credential.key
        } else if (!lastCredSelected) {
            selectedKey = credRepeater.model[findSelectedIndex() + 1].credential.key
        }

    }

    onGoUp: {
        flickable.flick(0, 300)
        if (nothingSelected) {
            selectedKey = lastCred.credential.key
        } else if (!firstCredSeleced) {
            selectedKey = credRepeater.model[findSelectedIndex() - 1].credential.key
        }
    }

    Keys.onReturnPressed: generateOrCopy()
    Keys.onEnterPressed: generateOrCopy()
    Keys.onEscapePressed: deselectCredential()
}
