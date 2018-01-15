import QtQuick 2.5
import "utils.js" as Utils

Item {
    property var credentials
    property int nCreds: credentials.length
    property bool nothingSelected: selectedKey === null
    property var firstCred: credentials[0]
    property var lastCred: credentials[nCreds - 1]
    property bool lastCredSelected: lastCred !== undefined && selectedKey === lastCred.credential.key
    property bool firstCredSeleced: firstCred !== undefined && selectedKey === firstCred.credential.key

    signal goDown()
    signal goUp()

    Keys.onDownPressed: goDown()
    Keys.onUpPressed: goUp()

    function findSelectedIndex() {
        return Utils.findIndex(credentials, function(entry) {
            return entry.credential.key === selectedKey
        }) || null
    }

    onGoDown: {
        if (nCreds > 0) {
            if (nothingSelected) {
                selectedKey = firstCred.credential.key
            } else if (!lastCredSelected) {
                flickable.flick(0, -300)
                selectedKey = credentials[findSelectedIndex() + 1].credential.key
            }
        }
    }

    onGoUp: {
        if (nCreds > 0) {
            if (nothingSelected) {
                selectedKey = lastCred.credential.key
            } else if (!firstCredSeleced) {
                flickable.flick(0, 300)
                selectedKey = credentials[findSelectedIndex() - 1].credential.key
            }
        }
    }

    Keys.onReturnPressed: generateOrCopy()
    Keys.onEnterPressed: generateOrCopy()
    Keys.onEscapePressed: deselectCredential()
}
