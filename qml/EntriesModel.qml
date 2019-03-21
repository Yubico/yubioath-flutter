import QtQuick 2.9

ListModel {

    function addEntry(entry) {
        append(entry)
    }

    function hasEntry(entry) {
        for (var j = 0; j < entries.count; j++) {
            if (get(j).credential.key === entry.credential.key) {
                return true
            }
        }
        return false
    }

    function updateEntry(entry) {
        for (var j = 0; j < count; j++) {
            if (get(j).credential.key === entry.credential.key) {
                set(j, entry)
            }
        }
    }
}
