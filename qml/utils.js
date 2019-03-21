function getNow() {
    // Use seconds since epoch, because
    // that is what we get from the python layer.
    return Math.floor(Date.now() / 1000)
}

function versionString(version) {
    return version ? version.join('.') : ''
}

function versionGE(version, major, minor, micro) {
    if (version != undefined) {
        return (version[0] > major || (version[0] == major
                                       && (version[1] > minor
                                           || (version[1] == minor
                                               && version[2] >= micro))))
    }
    return false
}

// Shim for String.prototype.startsWith(), added in Qt 5.8
// Reference: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/startsWith
function startsWith(string, search, pos) {
    return string.substr(!pos || pos < 0 ? 0 : +pos, search.length) === search
}

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
