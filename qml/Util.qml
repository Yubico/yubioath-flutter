import QtQuick 2.5

Item {
    visible: false

    /*
     * Quick and dirty shim for Array.find added in Qt 5.9
     *
     * @param items: array
     * @param predicate: function(any) => Boolean
     * @return The first `item` in `arr` that matches the `predicate`, or
     *          `undefined` if none matches
     */
    function find(items, predicate) {
        if (items) {
            for (var i = 0; i < items.length; ++i) {
                if (predicate(items[i])) {
                    return items[i]
                }
            }
        }
        return undefined
    }

    /*
     * Quick and dirty shim for Array.findIndex added in Qt 5.9
     *
     * @param items: array
     * @param predicate: function(any) => Boolean
     * @return The index of the first `item` in `arr` that matches the
     *          `predicate`, or `undefined` if none matches
     */
    function findIndex(items, predicate) {
        if (items) {
            for (var i = 0; i < items.length; ++i) {
                if (predicate(items[i])) {
                    return i
                }
            }
        }
        return undefined
    }

}
