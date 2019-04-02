import QtQuick 2.9

ListModel {
    function updateEntry(entry) {
        for (var j = 0; j < count; j++) {
            if (get(j).credential.key === entry.credential.key) {
                set(j, entry)
                return
            }
        }
        append(entry)
    }

    function updateEntries(entries) {
        // Update new ones
        for (var j = 0; j < entries.length; j++) {
            updateEntry(entries[j])
        }
        // TODO: clear out deleted ones ?
    }
}
